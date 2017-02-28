#!/usr/bin/env bash

ARG_GIT_SYNC_REPO=${ARG_GIT_SYNC_REPO:-}
ARG_GIT_SYNC_BRANCH=${ARG_GIT_SYNC_BRANCH:-"master"}
#ARG_GIT_SYNC_DEST=${ARG_GIT_SYNC_DEST:-}
#ARG_GIT_SYNC_REV=${ARG_GIT_SYNC_REV:-}
#GIT_ROOT="/git"
GIT_ROOT="/var/www/test/git"
#SSH_KEY_DIR="/etc/secret/"
SSH_KEY_DIR="/var/www/test/.ssh/"
#SSH_KEY_FILE="ssh.key"
SSH_KEY_FILE="gitsync1_id_rsa"
ARG_SSH_KEY_DATA=${ARG_SSH_KEY_DATA:-}
ARG_GIT_FETCH_SLEEP=${ARG_GIT_FETCH_SLEEP:-"60"}
export ARG_DEBUG=${ARG_DEBUG:-}

#export ARG_GIT_SYNC_REPO=git@dev.pgsk.sk:mvc.git
#export ARG_GIT_SYNC_BRANCH=master
#export ARG_DEBUG=1
#export ARG_GIT_SYNC_REPO=git@dev.pgsk.sk:mvc.git
#export ARG_GIT_SYNC_BRANCH=test_gitsync
#export ARG_DEBUG=1


debug_string (){
    local MESSAGE=$1
    if [ ! -z ${ARG_DEBUG} ] ; then
        echo "# ${MESSAGE}"
    fi
}
prepare_ssh (){

    local SSH_KEY_DIR=$1
    local SSH_KEY_FILE=$2
    local SSH_KEY_DATA=$3
    local SSH_KEY="$SSH_KEY_DIR/$SSH_KEY_FILE"

    #if not exists ssh_key_dir mkdir
    if [ ! -d "${SSH_KEY_DIR}" ]; then
        debug_string "mkdir -p ${SSH_KEY_DIR}"
        mkdir -p ${SSH_KEY_DIR}
    fi

    #if !empty SSH_KEY_DATA && empty ssh_key_dir , create private key file
    if [ ! -z "${SSH_KEY_DATA}" ] && [ ! -f "SSH_KEY" ] ; then
        debug_string "echo ${SSH_KEY_DATA} | base64 -d - > ${SSH_KEY}"
        echo ${SSH_KEY_DATA} | base64 -d - > ${SSH_KEY}
    fi

    if [ ! -f ${SSH_KEY} ] ; then
        echo "Missing ssh key file";
        exit 1
    fi

    #setup ssh GIT_SSH_COMMAND = ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i %s", SSH_KEY
    debug_string "GIT_SSH_COMMAND=\"ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${SSH_KEY}\""
    GIT_SSH_COMMAND="ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${SSH_KEY}"
}
git_clone (){
    local GIT_ROOT=$1
    local GIT_SYNC_REPO=$2
    local GIT_SYNC_BRANCH=$3

    #create GIT_ROOT if not exits
    debug_string "Create ${GIT_ROOT} if [ ! -d "${GIT_ROOT}" ]"
    if [ ! -d "${GIT_ROOT}" ] ; then
        debug_string "mkdir -p ${GIT_ROOT}"
        mkdir -p ${GIT_ROOT}
    fi


    #check if exists GIT_ROOT/.git
    #clone
    #git clone --no-checkout -b GIT_SYNC_BRANCH --depth 1 GIT_SYNC_REPO GIT_ROOT
    debug_string "Clone if [ ! -d "${GIT_ROOT}/.git" ]"
    if [ ! -d "${GIT_ROOT}/.git" ] ; then
        debug_string "git clone --no-checkout -b ${GIT_SYNC_BRANCH} --depth 1 ${GIT_SYNC_REPO} ${GIT_ROOT}"
        git clone --no-checkout -b ${GIT_SYNC_BRANCH} --depth 1 ${GIT_SYNC_REPO} ${GIT_ROOT}
    fi
}
git_fetch (){
    local GIT_ROOT=$1
    local GIT_SYNC_BRANCH=$2

    #cd inside
    debug_string "cd ${GIT_ROOT}"
    cd ${GIT_ROOT}

    #fetch data
    debug_string "git fetch --tags origin ${GIT_SYNC_BRANCH}"
    git fetch --tags origin ${GIT_SYNC_BRANCH}
}
git_get_fetch_head_hash (){
    local GIT_ROOT=$1

    #cd inside
    debug_string "cd ${GIT_ROOT}"
    cd ${GIT_ROOT}

    #get FETCH_HEAD revision
    #$hash = git rev-list -n1 FETCH_HEAD
    debug_string "REV_HASH=$(git rev-list -n1 FETCH_HEAD)"
    eval "$2=$(git rev-list -n1 FETCH_HEAD)"


}
new_git_worktree (){
    local GIT_ROOT=$1
    local WORK_DIR_TREE_NAME=$2
    local GIT_SYNC_BRANCH=$3

    #cd inside
    debug_string "cd ${GIT_ROOT}"
    cd ${GIT_ROOT}

    #new worktree
    debug_string "git worktree add ${WORK_DIR_TREE_NAME} origin/${GIT_SYNC_BRANCH}"
    git worktree add ${WORK_DIR_TREE_NAME} origin/${GIT_SYNC_BRANCH}

    #fix gitdir reference to relative path
    debug_string "echo \"gitdir: ../.git/worktrees/${WORK_DIR_TREE_NAME}\" > ${WORK_DIR_TREE_NAME}/.git"
    echo "gitdir: ../.git/worktrees/${WORK_DIR_TREE_NAME}" > ${WORK_DIR_TREE_NAME}/.git


}
remove_symlink_and_target (){
    local GIT_ROOT=$1
    local LINK_NAME=$2

    #cd inside
    debug_string "cd ${GIT_ROOT}"
    cd ${GIT_ROOT}

    if [ ! -L ${LINK_NAME} ] ; then
        return ;
    fi
    debug_string "LINK_TARGET=\$(readlink ${LINK_NAME})"
    LINK_TARGET=$(readlink ${LINK_NAME})

    if [ ! -z ${LINK_TARGET} ] ; then
        if [[ ! ${LINK_TARGET} == *"/"* ]] && [[ ! ${LINK_TARGET} == *".."* ]] ; then
            debug_string "rm -rf ${LINK_TARGET}"
            rm -rf ${LINK_TARGET}
        else
            echo "${LINK_NAME} is linked to a path containing '/' or '..'. Will delete only link. LINK_TARGET='${LINK_TARGET}'"
        fi
    fi
    if [ -L ${LINK_NAME} ] ; then
        debug_string "rm -rf ${LINK_NAME}"
        rm -rf ${LINK_NAME}
    fi

}


create_symlink (){
    local GIT_ROOT=$1
    local WORK_DIR_TREE_NAME=$2

    #cd inside
    debug_string "cd ${GIT_ROOT}"
    cd ${GIT_ROOT}

    #tmp symlink
    debug_string "ln -snf ${WORK_DIR_TREE_NAME} tmp-link"
    ln -snf ${WORK_DIR_TREE_NAME} tmp-link

    #move prev-prev link to git-del
    if [ -L "git-prev" ]; then
        debug_string "mv -Tf git-prev git-del"
        mv -Tf git-prev git-del
    fi
    if [ -a "git-prev" ]; then
        echo "git-prev was not a symlink. Moving to git-prev-error."
        debug_string "mv -Tf git-prev git-prev-error"
        mv -Tf git-prev git-prev-error
    fi
    if [ -L "git" ]; then
        debug_string "mv -Tf git git-prev"
        mv -Tf git git-prev
    fi
    if [ -a "git" ]; then
        echo "git was not a symlink. Moving to git-error."
        debug_string "mv -Tf git git-error"
        mv -Tf git git-error
    fi


    #replace symlink
    debug_string "mv -Tf tmp-link git"
    mv -Tf tmp-link git



}









prepare_ssh ${SSH_KEY_DIR} ${SSH_KEY_FILE} ${ARG_SSH_KEY_DATA}
git_clone ${GIT_ROOT} ${ARG_GIT_SYNC_REPO} ${ARG_GIT_SYNC_BRANCH}


while true
do

    git_fetch ${GIT_ROOT} ${ARG_GIT_SYNC_BRANCH}

    REV_HASH=""
    git_get_fetch_head_hash ${GIT_ROOT} REV_HASH
    debug_string "REV_HASH=${REV_HASH}"
    if [ -z ${REV_HASH} ] ; then
        echo "could not get FETCH_HEAD rev hash. exit."
        continue
    fi

    #workTreeDirName = rev-$hash
    debug_string "WORK_DIR_TREE_NAME=\"rev-${REV_HASH}\""
    WORK_DIR_TREE_NAME="rev-${REV_HASH}"

    #if this is a new commit
    if [ ! -f ${WORK_DIR_TREE_NAME}/.git ] ; then
        new_git_worktree ${GIT_ROOT} ${WORK_DIR_TREE_NAME} ${ARG_GIT_SYNC_BRANCH}

        if [ ! -f ${WORK_DIR_TREE_NAME}/.git ] ; then
            echo "Unsuccessful in creating new worktree";
            continue
        fi


        #app init in ${WORK_DIR_TREE_NAME}
        #composer install
        #symfony console cache init





        create_symlink ${GIT_ROOT} ${WORK_DIR_TREE_NAME}
        remove_symlink_and_target ${GIT_ROOT} 'git-del'
    fi

    sleep ${ARG_GIT_FETCH_SLEEP}

done


