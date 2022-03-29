bash stop_and_clean.sh
sudo podman build -t neurodesktop:latest .
sudo podman run --shm-size=1gb -it --privileged --name neurodesktop -v ~/neurodesktop-storage:/neurodesktop-storage -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" -p 8080:8080 neurodesktop:latest --debug
# -e CVMFS_DISABLE=true # will disable CVMFS for testing purposes