#!/usr/bin/env bash

ARG_GIT_SYNC_REPO=${ARG_GIT_SYNC_REPO:-}
ARG_GIT_SYNC_BRANCH=${ARG_GIT_SYNC_BRANCH:-}
#ARG_GIT_SYNC_DEST=${ARG_GIT_SYNC_DEST:-}
#ARG_GIT_SYNC_REV=${ARG_GIT_SYNC_REV:-}
#GIT_ROOT="/git"
GIT_ROOT="/var/www/test/git"
#SSH_KEY_DIR="/etc/secret/"
SSH_KEY_DIR="/var/www/test/.ssh/"
#SSH_KEY_FILE="ssh.key"
SSH_KEY_FILE="gitsync1_id_rsa"
ARG_SSH_KEY_DATA=${ARG_SSH_KEY_DATA:-}
export ARG_DEBUG=${ARG_DEBUG:-}

#export ARG_GIT_SYNC_REPO=git@dev.pgsk.sk:mvc.git
#export ARG_GIT_SYNC_BRANCH=master
#export ARG_DEBUG=1
#export ARG_GIT_SYNC_REPO=git@dev.pgsk.sk:mvc.git
#export ARG_GIT_SYNC_BRANCH=test_gitsync
#export ARG_DEBUG=1


debug_string (){
    if [ ! -z ${ARG_DEBUG} ] ; then
        echo "# $1"
    fi
}

#if not exists ssh_key_dir mkdir
if [ ! -d "$SSH_KEY_DIR" ]; then
    debug_string "mkdir -p ${SSH_KEY_DIR}"
    mkdir -p ${SSH_KEY_DIR}
fi

#if !empty SSH_KEY_DATA && empty ssh_key_dir , create private key file
if [ ! -z "$ARG_SSH_KEY_DATA" ] && [ ! -f "$SSH_KEY_DIR/$SSH_KEY_FILE" ] ; then
    debug_string "echo ${ARG_SSH_KEY_DATA} | base64 -d - > ${SSH_KEY_DIR}/${SSH_KEY_FILE}"
    echo ${ARG_SSH_KEY_DATA} | base64 -d - > ${SSH_KEY_DIR}/${SSH_KEY_FILE}
fi


if [ ! -f "$SSH_KEY_DIR/$SSH_KEY_FILE" ] ; then
    echo "Missing ssh key file";
    exit 1
fi

#setup ssh GIT_SSH_COMMAND = ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i %s", pathToSSHSecret
debug_string "GIT_SSH_COMMAND=\"ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $SSH_KEY_DIR/$SSH_KEY_FILE\""
GIT_SSH_COMMAND="ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $SSH_KEY_DIR/$SSH_KEY_FILE"


#create GIT_ROOT if not exits
debug_string "Create $GIT_ROOT if [ ! -d "$GIT_ROOT" ]"
if [ ! -d "$GIT_ROOT" ] ; then
    debug_string "mkdir -p ${GIT_ROOT}"
    mkdir -p ${GIT_ROOT}
fi


#check if exists GIT_ROOT/.git
#clone
#git clone --no-checkout -b GIT_SYNC_BRANCH --depth 1 GIT_SYNC_REPO GIT_ROOT
debug_string "Clone if [ ! -d "$GIT_ROOT/.git" ]"
if [ ! -d "$GIT_ROOT/.git" ] ; then
    debug_string "git clone --no-checkout -b ${ARG_GIT_SYNC_BRANCH} --depth 1 ${ARG_GIT_SYNC_REPO} ${GIT_ROOT}"
    git clone --no-checkout -b ${ARG_GIT_SYNC_BRANCH} --depth 1 ${ARG_GIT_SYNC_REPO} ${GIT_ROOT}
fi



#cd inside
debug_string "cd ${GIT_ROOT}"
cd ${GIT_ROOT}


#fetch data
debug_string "git fetch --tags origin ${ARG_GIT_SYNC_BRANCH}"
git fetch --tags origin ${ARG_GIT_SYNC_BRANCH}


#get FETCH_HEAD revision
#$hash = git rev-list -n1 FETCH_HEAD
debug_string "REV_HASH=$(git rev-list -n1 FETCH_HEAD)"
REV_HASH=$(git rev-list -n1 FETCH_HEAD)
if [ -z ${REV_HASH} ] ; then
    echo "could not get FETCH_HEAD rev hash. exit."
    exit 1
fi


#workTreeDirName = rev-$hash
debug_string "WORK_DIR_TREE_NAME=\"rev-$REV_HASH\""
WORK_DIR_TREE_NAME="rev-$REV_HASH"





#new worktree
debug_string "git worktree add ${WORK_DIR_TREE_NAME} origin/${ARG_GIT_SYNC_BRANCH}"
git worktree add ${WORK_DIR_TREE_NAME} origin/${ARG_GIT_SYNC_BRANCH}

#fix gitdir reference to relative path
debug_string "echo \"gitdir: ../.git/worktrees/${WORK_DIR_TREE_NAME}\" > ${WORK_DIR_TREE_NAME}/.git"
echo "gitdir: ../.git/worktrees/${WORK_DIR_TREE_NAME}" > ${WORK_DIR_TREE_NAME}/.git


#tmp symlink
debug_string "ln -snf ${WORK_DIR_TREE_NAME} tmp-link"
ln -snf ${WORK_DIR_TREE_NAME} tmp-link


#replace symlink
debug_string "mv -T tmp-link git"
mv -T tmp-link git




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

