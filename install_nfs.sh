export ROOT_DEV=$(findmnt -n -o SOURCE / | sed -E 's|/dev/||; s/[0-9]+$//')
export MNT=$(lsblk -nr -o NAME,MOUNTPOINT | awk -v root="$ROOT_DEV" '$2 != "" && $1 !~ "^"root {print $1; exit}')
export MNT_PATH=$(findmnt -n -o TARGET /dev/$MNT | head -n 1 )

TIMEOUT=300
SLEEP=2


elapsed=0
envsubst < nfs-server.yaml.template > nfs-server.yaml
kubectl apply -f ./nfs-server.yaml
curl -skSL https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/v4.11.0/deploy/install-driver.sh | bash -s v4.11.0 --
while [ $elapsed -lt $TIMEOUT ]; do
  POD_NAME=$(kubectl get pods -n kube-system --no-headers | grep "csi-nfs-node" | awk '{print $1}')
  if [ -n "$POD_NAME" ]; then
    STATUS=$(kubectl get pod "$POD_NAME" -n kube-system -o jsonpath='{.status.phase}')
    echo "Pod $POD_NAME status: $STATUS"
    if [ "$STATUS" = "Running" ]; then
      sleep 2
      kubectl apply -f nfs_sc.yaml
      break
    else
      echo "Pod $POD_NAME is in status: $STATUS"
    fi
  else
    echo "🔍 Pod matching 'nfs-server' not found yet."
  fi
  sleep $SLEEP
  elapsed=$((elapsed + SLEEP))
done

if [ $elapsed -ge $TIMEOUT ]; then
  echo "❌ Timed out waiting for pod to be running."
  exit 1
fi
