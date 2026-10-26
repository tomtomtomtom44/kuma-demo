# Migration vers Cloudflare Tunnel

## Objectif

Cette migration remplace l'exposition publique des applications via le
NodeBalancer LKE par des routes Cloudflare Tunnel vers les Services Kubernetes
internes. Cloudflare fournit le point d'entree HTTPS public et Access peut
exiger une authentification ou appliquer des policies avant de transmettre les
requêtes.

Le tunnel est distant et gere depuis Cloudflare. Les connecteurs `cloudflared`
du cluster etablissent des connexions sortantes vers Cloudflare; aucun port
entrant public n'est necessaire pour eux.

## Chemin du trafic

```text
Navigateur -- HTTPS --> Cloudflare Edge -- tunnel chiffre --> cloudflared
             -- HTTP interne --> Service ClusterIP de l'application --> Pod
```

Le certificat visible dans le navigateur est le certificat Edge presente par
Cloudflare. Le dernier segment, de `cloudflared` au Service applicatif, est en
HTTP dans le cluster pour les routes configurees ainsi. Ce n'est pas du TLS de
bout en bout jusqu'au pod.

## Configuration Kubernetes

### Secret du tunnel

Le token du tunnel est conserve dans Infisical sous le chemin `/divers-infra`,
cle `cloudflaretunnel`. Le manifeste
[`infisical-secrets/external-secrets-cloudflare.yaml`](../infisical-secrets/external-secrets-cloudflare.yaml)
cree le namespace `cloudflare` et un ExternalSecret utilisant le
ClusterSecretStore `infisical-infra`. Il genere le Secret Kubernetes `cloudflared`
avec la cle `TUNNEL_TOKEN`.

Le token est injecte dans le Deployment comme variable d'environnement et ne
doit pas etre copie dans le depot Git.

### Connecteurs cloudflared

Le chart [`helm/cloudflared`](../helm/cloudflared) configure deux replicas avec
anti-affinite obligatoire par noeud. Le rollout remplace un connecteur a la
fois et ne demande pas de troisieme pod temporaire. Aucun Service Kubernetes
public n'est cree.

Commandes utiles depuis la racine du depot :

```sh
kubectl get externalsecret cloudflared -n cloudflare
helm upgrade --install cloudflared ./helm/cloudflared \
  --namespace cloudflare --create-namespace
kubectl rollout status deployment/cloudflared -n cloudflare
kubectl get pods -n cloudflare -o wide
kubectl logs -n cloudflare -l app.kubernetes.io/instance=cloudflared --since=15m --prefix=true
```

Un connecteur actif suffit au fonctionnement, mais pas a la tolerance a la
panne d'un noeud. L'etat observe le 26 octobre 2026 est un pod `Running` sur
`lke516992-746510-50c6aba20000` et un second `Pending`, car l'autre noeud n'a
pas assez de CPU reservable. Ne pas relacher l'anti-affinite pour masquer ce
manque de capacite si l'objectif est une vraie redondance entre noeuds.

## DNS et zone Cloudflare

Le domaine est enregistre chez Namecheap, mais ses nameservers deleguent
maintenant la zone `linguaplay.app` a Cloudflare. Namecheap reste le registrar;
Cloudflare est l'autorite DNS.

Avant de changer les nameservers, les enregistrements DNS existants ont ete
recrees dans Cloudflare, notamment les enregistrements A du domaine racine et
de `staging`, ainsi que les MX/TXT utilises par le courrier, DMARC et Resend.
Les enregistrements de courrier doivent rester en mode **DNS only**.

Le tunnel utilise l'UUID `944db275-8cff-4b93-865e-50cfea80eb22` et porte le nom
`donthomas-infra`. Lorsqu'un hostname n'est pas cree automatiquement par le
dashboard, son CNAME Cloudflare cible le nom de tunnel officiel :

```text
<hostname> CNAME 944db275-8cff-4b93-865e-50cfea80eb22.cfargotunnel.com
```

Le nom du record est le sous-domaine, par exemple `staging`, et le proxy
Cloudflare doit etre actif. Le CNAME remplace l'ancien A record au meme nom; A
et CNAME ne doivent pas coexister pour `staging`. Pour l'apex `linguaplay.app`,
Cloudflare applique le CNAME flattening, ce qui explique l'avertissement de
console sur le CNAME a l'apex.

Les DNS pointent vers le tunnel; les routes publiees dans Cloudflare associent
separement chaque hostname a un Service Kubernetes.

## Access

L'application Access de test creee dans Cloudflare est
`linguaplay-staging-tunnel-test` pour `tunnel-test.linguaplay.app`. Elle utilise
la policy `staging access`, qui autorise les IP de staging configurees. Le
signin Cloudflare observe au test est normal : policy IP et authentification
Access sont des controles distincts.

Les hostnames staging et production doivent chacun etre associes a la policy
voulue. Ne pas supposer qu'une policy attachee a un hostname est automatiquement
appliquee a un autre.

Le reglage optionnel « Protect with Access » dans la route du tunnel valide le
JWT Access en plus de la protection de l'application Access. Il demande le team
name Zero Trust et l'AUD tag de l'application. Il peut rester desactive pour
une configuration plus simple : la policy de l'application Access reste
appliquee a l'edge. S'il est active, copier team name et AUD depuis les reglages
Cloudflare correspondants; ne pas les deduire de l'UUID du tunnel.

## Hostnames et origines

Routes publiees configurees :

| Environnement | Hostname public | Origine Kubernetes |
| --- | --- | --- |
| Test | `tunnel-test.linguaplay.app` | `http://linguaplay-staging.linguaplay-staging.svc.cluster.local:80` |
| Staging | `staging.linguaplay.app` | Service de l'application staging sur son port HTTP interne |
| Production | `linguaplay.app` | Service de l'application production sur son port HTTP interne |

Confirmer le nom et le port exacts des Services dans le cluster avant toute
modification de route :

```powershell
kubectl get svc -n linguaplay-staging
kubectl get svc -n linguaplay
```

Les routes Cloudflare actuelles contournent ingress-nginx et ciblent directement
les Services. Les applications doivent donc repondre correctement sur le port
interne indique. Ne pas router directement vers ingress-nginx tant que sa
configuration de protocole ne correspond pas au trafic HTTP ordinaire de
`cloudflared`.

## Retrait de l'exposition publique nginx

Le chart [`helm/nginx-ingress`](../helm/nginx-ingress) a ete modifie pour
conserver le controleur comme service interne :

- Service du controleur `ClusterIP`, sans NodePort ni NodeBalancer;
- `use-proxy-protocol: "false"`, car les clients internes n'envoient pas le
  PROXY protocol;
- deux replicas avec anti-affinite et un rollout `maxSurge: 0`.

L'upgrade applique a change le Service en `ClusterIP`. L'etat du cluster verifie
le 26 octobre 2026 confirme `EXTERNAL-IP: <none>` et une adresse interne
`10.128.25.35`; le NodeBalancer associe a ce Service n'est donc plus expose.
Les objets Ingress Kubernetes restent presents et leurs adresses sont internes.

Cette modification ne supprime pas nginx. Le controleur est encore necessaire
aux ressources Ingress existantes et au ClusterIssuer `letsencrypt-http` tant
que ce dernier utilise HTTP-01 avec `ingress.class: nginx`.

## Certificats

Les certificats Kubernetes `nextjs-tls` et `nextjs-tls-staging` sont encore
`Ready=True` et emis par `letsencrypt-http`. Le fait que les certificats
Cloudflare Edge servent le trafic public ne remplace pas automatiquement le
cycle de renouvellement cert-manager dans le cluster.

Avant de retirer ingress-nginx ou ses Ingress, migrer cert-manager vers une
validation qui ne depend pas d'eux, par exemple DNS-01 avec un token API
Cloudflare aux permissions minimales sur la zone `linguaplay.app`. Stocker ce
token dans Infisical et un Secret Kubernetes; ne jamais le committer. Tester un
renouvellement/certificate de test avant de retirer le solver HTTP-01.

## Validation apres bascule

Pour chaque hostname, verifier :

1. Le hostname resout vers Cloudflare et l'application Access presente la
   policy attendue.
2. Un client autorise peut s'authentifier et l'application repond apres signin.
3. Un client non autorise est refuse par la policy.
4. Les logs cloudflared ne montrent pas d'erreurs d'origine; les messages
   d'enregistrement de connexions QUIC indiquent que les connecteurs sont
   connectes, mais ne prouvent pas a eux seuls que l'origine applicative
   fonctionne.
5. Le site et les enregistrements mail fonctionnent apres la delegation DNS.

Commandes de diagnostic :

```powershell
kubectl get pods -n cloudflare -o wide
kubectl logs -n cloudflare -l app.kubernetes.io/instance=cloudflared --since=15m --prefix=true
kubectl get svc -n linguaplay-staging
kubectl get svc -n linguaplay
kubectl get certificates -A
```

## Retour arriere

Tant que le NodeBalancer est conserve, le retour du trafic d'un hostname peut
se faire en restaurant son ancien A record vers l'IP du NodeBalancer, a
condition que la route et les listeners existent encore. La delegation DNS
Cloudflare peut rester en place pendant ce retour : il suffit de modifier le
record autoritaire dans Cloudflare.

Si le NodeBalancer a ete supprime, restaurer l'ancien A record seul ne suffit
pas. Il faut d'abord remettre ingress-nginx en `LoadBalancer`, recreer le
NodeBalancer et attendre qu'il soit sain, puis mettre a jour le DNS. Le
NodeBalancer peut obtenir une nouvelle IP; ne pas supposer que l'ancienne sera
reattribuee.

Ne supprimer le controleur ingress-nginx qu'apres avoir retire ou migre ses
Ingress et remplace/valide le solver HTTP-01 de cert-manager. Les enregistrements
MX/TXT et les services mail ne doivent pas etre modifies pendant le retour
arriere web.