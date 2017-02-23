#!/usr/bin/env bash

ARG_GIT_SYNC_REPO=${ARG_GIT_SYNC_REPO:-}
ARG_GIT_SYNC_BRANCH=${ARG_GIT_SYNC_BRANCH:-}
ARG_GIT_SYNC_DEST=${ARG_GIT_SYNC_DEST:-}
ARG_GIT_SYNC_REV=${ARG_GIT_SYNC_REV:-}
GIT_ROOT="/git"
SSH_KEY_DIR="/etc/secret/"
SSH_KEY_FILE="ssh.key"
ARG_SSH_KEY_DATA=${ARG_SSH_KEY_DATA:-}

#if not exists ssh_key_dir mkdir
if [ ! -d "$SSH_KEY_DIR" ]; then
    mkdir -p ${SSH_KEY_DIR}
fi
#if !empty SSH_KEY_DATA && empty ssh_key_dir , create private key file
if [ ! -z "$ARG_SSH_KEY_DATA" ] && [ ! -f "$SSH_KEY_DIR/$SSH_KEY_FILE" ] ; then
    echo ${ARG_SSH_KEY_DATA} | base64 -d - > ${SSH_KEY_DIR}/${SSH_KEY_FILE}
fi

if [ ! -f "$SSH_KEY_DIR/$SSH_KEY_FILE" ] ; then
    echo "Missing ssh key file";
    exit 1
fi

#setup ssh GIT_SSH_COMMAND = ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i %s", pathToSSHSecret
GIT_SSH_COMMAND="ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $SSH_KEY_DIR/$SSH_KEY_FILE"

#check if exists GIT_ROOT/.git
#clone
#git clone --no-checkout -b GIT_SYNC_BRANCH --depth 1 GIT_SYNC_REPO GIT_ROOT
if [ ! -d "$GIT_ROOT/.git" ] ; then
    git clone --no-checkout -b GIT_SYNC_BRANCH --depth 1 GIT_SYNC_REPO GIT_ROOT
fi



#cd inside
#cd GIT_ROOT

#get HEAD revision
#$hash = git rev-list -n1 HEAD

#fetch data
#git fetch --tags origin GIT_SYNC_BRANCH

#workTreeDirName = rev-$hash

#new worktree
#git worktree add $workTreeDirName origin/GIT_SYNC_BRANCH

#fix gitdir reference to relative path
#echo "gitdir: ../.git/worktrees/$workTreeDirName" > $workTreeDirName/.git

#tmp symlink
#ln -snf rev-bc33cf21b096db4ba76535bf66ad20066fe3d216 tmp-link

#replace symlink
#mv -T tmp-link git




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

