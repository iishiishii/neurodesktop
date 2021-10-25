#things in .bashrc get executed for every subshell
if [ -f '/usr/share/module.sh' ]; then source /usr/share/module.sh; fi

alias ll='ls -la'

if [ -d /cvmfs/neurodesk.ardc.edu.au/neurodesk-modules ]; then
        # export MODULEPATH="/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules"
        module use /cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/*
else
        export MODULEPATH="/neurodesktop-storage/containers/modules"              
        module use $MODULEPATH
        export CVMFS_DISABLE=true
fi


if [ -f '/usr/share/module.sh' ]; then
        echo 'Run "ml av" to see which tools are available - use "ml <tool>" to use them in this shell.'
        if [ -v "$CVMFS_DISABLE" ]; then
                if [ ! -d $MODULEPATH ]; then
                        echo 'Neurodesk tools not yet downloaded. Choose tools to install from the Application menu.'
                fi
        fi
fi

export PATH="/usr/local/singularity/bin:/home/user/.local/bin:${PATH}"

# SETUP miniconda - but only if CVMFS is available
if [ ! -v "$CVMFS_DISABLE" ]; then
        # !! Contents within this block are managed by 'conda init' !!
        __conda_setup="$('/cvmfs/neurodesk.ardc.edu.au/containers/condaenvs_1.0.0_20211011/condaenvs_1.0.0_20211011.simg/opt/miniconda-latest/condabin/conda' 'shell.bash' 'hook' 2> /dev/null)"
        if [ $? -eq 0 ]; then
        eval "$__conda_setup"
        else
        if [ -f "/cvmfs/neurodesk.ardc.edu.au/containers/condaenvs_1.0.0_20211011/condaenvs_1.0.0_20211011.simg/opt/miniconda-latest/etc/profile.d/conda.sh" ]; then
                . "/cvmfs/neurodesk.ardc.edu.au/containers/condaenvs_1.0.0_20211011/condaenvs_1.0.0_20211011.simg/opt/miniconda-latest/etc/profile.d/conda.sh"
        else
                export PATH="/cvmfs/neurodesk.ardc.edu.au/containers/condaenvs_1.0.0_20211011/condaenvs_1.0.0_20211011.simg/opt/miniconda-latest/bin:$PATH"
        fi
        fi
        unset __conda_setup
        # <<< conda initialize <<<
fi
# Always leave an empty line at the end of this file so we can add things during startup
