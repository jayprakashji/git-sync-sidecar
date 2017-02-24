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
create_symlink (){
    local GIT_ROOT=$1
    local WORK_DIR_TREE_NAME=$2

    #cd inside
    debug_string "cd ${GIT_ROOT}"
    cd ${GIT_ROOT}

    #tmp symlink
    debug_string "ln -snf ${WORK_DIR_TREE_NAME} tmp-link"
    ln -snf ${WORK_DIR_TREE_NAME} tmp-link


    #replace symlink
    debug_string "mv -T tmp-link git"
    mv -T tmp-link git

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

    fi

    sleep ${ARG_GIT_FETCH_SLEEP}

done




#history
#  850  2017-02-22 10:22:20 cd /var/www/
#  851  2017-02-22 10:22:21 ls
#  852  2017-02-22 10:22:33 mkdir test
#  853  2017-02-22 10:22:36 cd test/
#  854  2017-02-22 11:44:41 git clone --no-checkout -b master --depth 0 git@dev.pgsk.sk:mvc.git /var/www/test/git
#  855  2017-02-22 11:44:45 git clone --no-checkout -b master --depth 1 git@dev.pgsk.sk:mvc.git /var/www/test/git
#  856  2017-02-22 12:01:25 mc
#  857  2017-02-22 12:02:39 git rev-list -n1
#  858  2017-02-22 12:03:56 cd git/
#  859  2017-02-22 12:04:02 git rev-list -n1
#  860  2017-02-22 12:04:59 git rev-list -n1 HEAD
#  861  2017-02-22 12:06:46 git fetch --tags origin master
#  862  2017-02-22 12:07:48 git worktree add rev-bc33cf21b096db4ba76535bf66ad20066fe3d216 origin/master
#  863  2017-02-22 13:20:01 less .git/worktrees/
#  864  2017-02-22 13:20:40 ls -halF .git/worktrees/rev-bc33cf21b096db4ba76535bf66ad20066fe3d216/
#  865  2017-02-22 13:20:45 ls -halF .git/worktrees/
#  866  2017-02-22 13:21:02 ls -halF
#  867  2017-02-22 13:21:47 ls -halF .git/worktrees/rev-bc33cf21b096db4ba76535bf66ad20066fe3d216/gitdir
#  868  2017-02-22 13:21:52 less .git/worktrees/rev-bc33cf21b096db4ba76535bf66ad20066fe3d216/gitdir
#  869  2017-02-22 13:22:11 ls -halF .git/worktrees/rev-bc33cf21b096db4ba76535bf66ad20066fe3d216/
#  870  2017-02-22 13:22:20 ls -halF rev-bc33cf21b096db4ba76535bf66ad20066fe3d216/
#  871  2017-02-22 13:22:33 less rev-bc33cf21b096db4ba76535bf66ad20066fe3d216/.git
#  872  2017-02-22 13:23:20 ls -halF /var/www/test/git/.git/worktrees/rev-bc33cf21b096db4ba76535bf66ad20066fe3d216
#  873  2017-02-22 13:39:18 ls /var/www/test/git/rev-bc33cf21b096db4ba76535bf66ad20066fe3d216/.git
#  874  2017-02-22 13:46:13 cat /var/www/test/git/rev-bc33cf21b096db4ba76535bf66ad20066fe3d216/.git
#  875  2017-02-22 14:26:44 echo "gitdir: ../.git/worktrees/rev-bc33cf21b096db4ba76535bf66ad20066fe3d216" > rev-bc33cf21b096db4ba76535bf66ad20066fe3d216/.git
#  876  2017-02-22 14:26:46 cat /var/www/test/git/rev-bc33cf21b096db4ba76535bf66ad20066fe3d216/.git
#  877  2017-02-22 14:46:49 man ln
#  878  2017-02-22 14:49:05 ln -snf rev-bc33cf21b096db4ba76535bf66ad20066fe3d216 tmp-link
#  879  2017-02-22 14:49:13 man mv
#  880  2017-02-22 14:51:57 mv -T tmp-link git

