# How to test/explore the X.509 certificate implementation

A Device/VM with a (SW)TPM is required.

## Prepare certificates for testing

```bash
cd ~
#### ATTENTION: Creating CA and using it. The following steps should not be done on the device but for this prototype this is done there.
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 365 -key ca.key -out ca.crt -subj "/CN=x.509_test CA"
# Create a device certificate
openssl genrsa -out device.key 2048
openssl req -new -key device.key -out device.csr -subj "/CN=Device"
openssl x509 -req -days 365 -in device.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out device.crt

# Add ca.crt to device.crt for cahin verification at dps
cat ca.crt >> device.crt

sudo cp ~/device_rsa.key /var/lib/aziot/keyd/device_rsa.key
sudo chown aziotks:aziotks /var/lib/aziot/keyd/device_rsa.key

sudo mkdir /var/secrets
sudo cp ~/device.crt /var/secrets/device.crt

# load stuff into variables
crt=$(echo device.crt)
key=$(echo device.key)
global_endpoint="https://global.azure-devices-provisioning.net"
scope_id=0ne00C58DDD
registration_id=Device

# Now test your scripts!
```

## Prepare SWTPM for testing

```bash
sudo tpm_server
sudo tpm2-abrmd --allow-root --tcti="/usr/lib/libtss2-tcti-mssim.so.0:host=127.0.0.1,port=2321"
```

## Configure IoT Edge

Example Toml file:

```toml
hostname = "nt080027285b95"

[provisioning]
source = "dps"
global_endpoint = ""https://global.azure-devices-provisioning.net"
id_scope ="0ne00C58DDD"

[provisioning.attestation]
method = "x509"
registration_id = "Device"
identity_pk = "pkcs11:token=azureiothub;object=device?pin-value=hilscher"
identity_cert = "file:///etc/aziot/device.crt"

[aziot_keys]
pkcs11_lib_path = "/usr/lib/pkcs11/libtpm2_pkcs11.so.0.0.0"

[agent]
name = "edgeAgent"
type = "docker"

[agent.config]
image = "mcr.microsoft.com/azureiotedge-agent:1.2"

[agent.env]
"storageFolder" = "/iotedge/storage"
"UpstreamProtocol" = "Amqp"

[moby_runtime]
uri = "unix:///run/iotedge-docker.sock"
network = "azure-iot-edge"
```
