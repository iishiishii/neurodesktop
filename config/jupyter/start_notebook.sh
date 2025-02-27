# This script runs in local Jupyterlab only (e.g. Docker, Neurodeskapp)
# This script does NOT run on stock JupterHub/BinderHub instances (e.g. kubernetes)
# For global startup script, see ./config/jupyter/jupterlab_startup.sh

if [ -z "$GRANT_SUDO" ]; then
export GRANT_SUDO='yes'
fi
if [ -z "$RESTARTABLE" ]; then
export RESTARTABLE='yes'
fi

HOME_UID=$(stat -c "%u" /home/${NB_USER})
HOME_GID=$(stat -c "%g" /home/${NB_USER})

if [[ "${NB_UID}" != "${HOME_UID}" || "${NB_GID}" != "${HOME_GID}" ]]; then
    if [ -z "$CHOWN_HOME" ]; then
    export CHOWN_HOME='yes'
    fi
    if [ -z "$CHOWN_HOME_OPTS" ]; then
    export CHOWN_HOME_OPTS='-R'
    fi
fi