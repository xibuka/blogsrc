---
title: "Kubernetes証明書の有効期限テスト"
date: 2021-06-23T17:34:31+09:00
draft: false
tags:
- K8s
---

業務の都合で、有効期限切れのKubernetesクラスタで証明書の更新手順を検証する必要がありました。
初めての作業だったので、ここに手順を記録します。

## kubeadmソースの修正とビルド

0. ビルド環境にgoとgitをインストールし、goのバイナリパスをPATHに追加します。

1. Kubernetesのソースコードをダウンロードします。今回はv1.18.18を使用しました。

   ```git clone -b v1.18.18 https://github.com/kubernetes/kubernetes```

2. 証明書の有効期間を10分に設定するため、以下のファイルを修正します：

   ```sh
   diff --git a/cmd/kubeadm/app/constants/constants.go b/cmd/kubeadm/app/constants/constants.go
   index b56891ca908..eed934280e7 100644
   --- a/cmd/kubeadm/app/constants/constants.go
   +++ b/cmd/kubeadm/app/constants/constants.go
   @@ -46,7 +46,8 @@ const (
   TempDirForKubeadm = "tmp"
   
   // CertificateValidity defines the validity for all the signed certificates generated by kubeadm
   - CertificateValidity = time.Hour * 24 * 365
   + //CertificateValidity = time.Hour * 24 * 365
   + CertificateValidity = time.Second * 600
   
   // CACertAndKeyBaseName defines certificate authority base name
   CACertAndKeyBaseName = "ca"
   diff --git a/staging/src/k8s.io/client-go/util/cert/cert.go b/staging/src/k8s.io/client-go/util/cert/cert.go
   index 9fd097af5e3..64e1dd90f43 100644
   --- a/staging/src/k8s.io/client-go/util/cert/cert.go
   +++ b/staging/src/k8s.io/client-go/util/cert/cert.go
   @@ -35,7 +35,8 @@ import (
   "k8s.io/client-go/util/keyutil"
   )
   
   -const duration365d = time.Hour * 24 * 365
   +//const duration365d = time.Hour * 24 * 365
   +const duration365d = time.Second * 600
   
   // Config contains the basic fields required for creating a certificate
   type Config struct {
   @@ -93,7 +94,8 @@ func GenerateSelfSignedCertKey(host string, alternateIPs []net.IP, alternateDNS
   // Certs/keys not existing in that directory are created.
   func GenerateSelfSignedCertKeyWithFixtures(host string, alternateIPs []net.IP, alternateDNS []string, fixtureDirectory string) ([]byte, []byte, error) {
   validFrom := time.Now().Add(-time.Hour) // valid an hour earlier to avoid flakes due to clock skew
   - maxAge := time.Hour * 24 * 365 // one year self-signed certs
   + //maxAge := time.Hour * 24 * 365 // one year self-signed certs
   + maxAge := time.Second * 600 // one year self-signed certs
   
   baseName := fmt.Sprintf("%s_%s_%s", host, strings.Join(ipsToStrings(alternateIPs), "-"), strings.Join(alternateDNS, "-"))
   certFixturePath := path.Join(fixtureDirectory, baseName+".crt")
   ```

3. 以下のコマンドでkubeadmのみをビルドします：

   ```make WHAT=cmd/kubeadm GOFLAGS=-v```

   ビルドが完了すると_outputフォルダが作成され、kubeadmバイナリはbinサブディレクトリに配置されます。
   このバイナリでクラスタをデプロイすると、証明書の有効期間は10分になります。

## 証明書の確認と更新

1. 3ノードクラスタを構築し、証明書の残り有効期間が約4分であることを確認します：

   ````bash
   root@wenhan-adm-cp:~# ./kubeadm alpha certs check-expiration
   [check-expiration] Reading configuration from the cluster...
   [check-expiration] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
   
   CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
   admin.conf                 Jun 24, 2021 06:01 UTC   4m                                      no
   apiserver                  Jun 24, 2021 06:01 UTC   4m              ca                      no
   apiserver-etcd-client      Jun 24, 2021 06:01 UTC   4m              etcd-ca                 no
   apiserver-kubelet-client   Jun 24, 2021 06:01 UTC   4m              ca                      no
   controller-manager.conf    Jun 24, 2021 06:01 UTC   4m                                      no
   etcd-healthcheck-client    Jun 24, 2021 06:01 UTC   4m              etcd-ca                 no
   etcd-peer                  Jun 24, 2021 06:01 UTC   4m              etcd-ca                 no
   etcd-server                Jun 24, 2021 06:01 UTC   4m              etcd-ca                 no
   front-proxy-client         Jun 24, 2021 06:01 UTC   4m              front-proxy-ca          no
   scheduler.conf             Jun 24, 2021 06:01 UTC   4m                                      no
   
   CERTIFICATE AUTHORITY   EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
   ca                      Jun 24, 2021 07:31 UTC   1h              no
   etcd-ca                 Jun 24, 2021 07:31 UTC   1h              no
   front-proxy-ca          Jun 24, 2021 07:31 UTC   1h              no
   
   root@wenhan-adm-cp:~# kubectl get node
   NAME             STATUS   ROLES    AGE     VERSION
   wenhan-adm-cp    Ready    master   4m35s   v1.18.18
   wenhan-adm-wk1   Ready    <none>   3m32s   v1.18.18
   wenhan-adm-wk2   Ready    <none>   3m28s   v1.18.18
   ````

2. 有効期限切れ後、kubectl get nodeは失敗します：

   ```bash
   root@wenhan-adm-cp:~# ./kubeadm alpha certs check-expiration
   [check-expiration] Reading configuration from the cluster...
   [check-expiration] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
   [check-expiration] Error reading configuration from the Cluster. Falling back to default configuration
   
   W0624 06:01:22.231290   13746 configset.go:202] WARNING: kubeadm cannot validate component configs for API groups [kubelet.config.k8s.io kubeproxy.config.k8s.io]
   CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
   admin.conf                 Jun 24, 2021 06:01 UTC   <invalid>                               no
   apiserver                  Jun 24, 2021 06:01 UTC   <invalid>       ca                      no
   apiserver-etcd-client      Jun 24, 2021 06:01 UTC   <invalid>       etcd-ca                 no
   apiserver-kubelet-client   Jun 24, 2021 06:01 UTC   <invalid>       ca                      no
   controller-manager.conf    Jun 24, 2021 06:01 UTC   <invalid>                               no
   etcd-healthcheck-client    Jun 24, 2021 06:01 UTC   <invalid>       etcd-ca                 no
   etcd-peer                  Jun 24, 2021 06:01 UTC   <invalid>       etcd-ca                 no
   etcd-server                Jun 24, 2021 06:01 UTC   <invalid>       etcd-ca                 no
   front-proxy-client         Jun 24, 2021 06:01 UTC   <invalid>       front-proxy-ca          no
   scheduler.conf             Jun 24, 2021 06:01 UTC   <invalid>                               no
   
   CERTIFICATE AUTHORITY   EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
   ca                      Jun 24, 2021 07:31 UTC   1h              no
   etcd-ca                 Jun 24, 2021 07:31 UTC   1h              no
   front-proxy-ca          Jun 24, 2021 07:31 UTC   1h              no
   
   root@wenhan-adm-cp:~# kubectl get node
   Unable to connect to the server: x509: certificate has expired or is not yet valid
   ```

3. 証明書を更新し、新しい有効期限を確認します：

   ```bash
   root@wenhan-adm-cp:~# ./kubeadm alpha certs renew all --config=kubeadm.yaml
   W0624 06:04:00.447612   2860 configset.go:202] WARNING: kubeadm cannot validate component configs for API groups [kubelet.config.k8s.io kubeproxy.config.k8s.io]
   certificate embedded in the kubeconfig file for the admin to use and for kubeadm itself renewed
   certificate for serving the Kubernetes API renewed
   certificate the apiserver uses to access etcd renewed
   certificate for the API server to connect to kubelet renewed
   certificate embedded in the kubeconfig file for the controller manager to use renewed
   certificate for liveness probes to healthcheck etcd renewed
   certificate for etcd nodes to communicate with each other renewed
   certificate for serving etcd renewed
   certificate for the front proxy client renewed
   certificate embedded in the kubeconfig file for the scheduler manager to use renewed
   ```

   更新後、各証明書の有効期限が更新されていることを確認します：

   ```bash
   root@wenhan-adm-cp:~# ./kubeadm alpha certs check-expiration
   [check-expiration] Reading configuration from the cluster...
   [check-expiration] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
   [check-expiration] Error reading configuration from the Cluster. Falling back to default configuration
   
   W0624 06:04:21.176808   3230 configset.go:202] WARNING: kubeadm cannot validate component configs for API groups [kubelet.config.k8s.io kubeproxy.config.k8s.io]
   CERTIFICATE         EXPIRES          RESIDUAL TIME  CERTIFICATE AUTHORITY  EXTERNALLY MANAGED
   admin.conf         Jun 24, 2021 06:14 UTC  9m                    no
   apiserver          Jun 24, 2021 06:14 UTC  9m        ca            no
   apiserver-etcd-client    Jun 24, 2021 06:14 UTC  9m        etcd-ca         no
   apiserver-kubelet-client  Jun 24, 2021 06:14 UTC  9m        ca            no
   controller-manager.conf   Jun 24, 2021 06:14 UTC  9m                    no
   etcd-healthcheck-client   Jun 24, 2021 06:14 UTC  9m        etcd-ca         no
   etcd-peer          Jun 24, 2021 06:14 UTC  9m        etcd-ca         no
   etcd-server         Jun 24, 2021 06:14 UTC  9m        etcd-ca         no
   front-proxy-client     Jun 24, 2021 06:14 UTC  9m        front-proxy-ca      no
   scheduler.conf       Jun 24, 2021 06:14 UTC  9m                    no
   
   CERTIFICATE AUTHORITY  EXPIRES          RESIDUAL TIME  EXTERNALLY MANAGED
   ca            Jun 24, 2021 07:31 UTC  1h        no
   etcd-ca         Jun 24, 2021 07:31 UTC  1h        no
   front-proxy-ca      Jun 24, 2021 07:31 UTC  1h        no
   ```

4. 証明書を更新した後、コントロールプレーンを再起動します：

   ```bash
   root@wenhan-adm-cp:~# reboot
   ```

   これで証明書の更新は完了です。

   再起動後、新しい認証ファイルでクラスタにアクセスできます：

   ```bash
   root@wenhan-adm-cp:~# cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   cp: overwrite '/root/.kube/config'? yes
   
   root@wenhan-adm-cp:~# kubectl get node
   NAME       STATUS  ROLES   AGE  VERSION
   wenhan-adm-cp   Ready   master  14m  v1.18.18
   wenhan-adm-wk1  Ready   <none>  13m  v1.18.18
   wenhan-adm-wk2  Ready   <none>  13m  v1.18.18
   ```
