export ROOT_DEV=$(findmnt -n -o SOURCE / | sed -E 's|/dev/||; s/[0-9]+$//')
export MNT=$(lsblk -nr -o NAME,MOUNTPOINT | awk -v root="$ROOT_DEV" '$2 != "" && $1 !~ "^"root {print $1; exit}')
export MNT_PATH=$(findmnt -n -o TARGET /dev/$MNT)

envsubst < nfs-server.yaml.template > nfs-server.yaml
kubectl apply -f ./nfs-server.yaml
sleep 2
curl -skSL https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/v4.11.0/deploy/install-driver.sh | bash -s v4.11.0 --
sleep 1
kubectl apply -f nfs_sc.yaml
