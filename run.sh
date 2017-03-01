#!/bin/sh

main() {
  # Fallback to global environment variables
  if [ -z "$WERCKER_DOCSET_PUBLISH_AWS_ACCESS_KEY_ID" ]; then
    WERCKER_DOCSET_PUBLISH_AWS_ACCESS_KEY_ID=$DOCSET_AWS_ACCESS_KEY_ID
  fi

  if [ -z "$WERCKER_DOCSET_PUBLISH_AWS_SECRET_ACCESS_KEY" ]; then
    WERCKER_DOCSET_PUBLISH_AWS_SECRET_ACCESS_KEY=$DOCSET_AWS_SECRET_ACCESS_KEY
  fi

  if [ -z "$WERCKER_DOCSET_PUBLISH_AWS_SESSION_TOKEN" ]; then
    WERCKER_DOCSET_PUBLISH_AWS_SESSION_TOKEN=$DOCSET_AWS_SESSION_TOKEN
  fi

  # Validate Input
  if [ -z "$WERCKER_DOCSET_PUBLISH_DOCSET" ]; then
    fail "docset: argument cannot be empty"
  fi

  if [ -z "$WERCKER_DOCSET_PUBLISH_BUCKET" ]; then
    fail "bucket: argument cannot be empty"
  fi

  if [ ! -d "$WERCKER_DOCSET_PUBLISH_DOCSET" ]; then
    fail "docset: directory not found '$WERCKER_DOCSET_PUBLISH_DOCSET'"
  fi

  if [ ! -z "$WERCKER_DOCSET_PUBLISH_GEMSPEC" ]; then
    if [ ! -d "$WERCKER_DOCSET_PUBLISH_GEMSPEC" ]; then
      fail "gemspec: file not found '$WERCKER_DOCSET_PUBLISH_GEMSPEC'"
    fi
  fi

  if [ -z "$WERCKER_DOCSET_PUBLISH_AWS_ACCESS_KEY_ID" ]; then
    fail "aws_access_key_id: argument emtpy and no default set"
  fi

  if [ -z "$WERCKER_DOCSET_PUBLISH_AWS_SECRET_ACCESS_KEY" ]; then
    fail "aws_secret_access_key: argument emtpy and no default set"
  fi

  if [ -z "$WERCKER_DOCSET_PUBLISH_AWS_SESSION_TOKEN" ]; then
    if [[ $WERCKER_DOCSET_PUBLISH_AWS_ACCESS_KEY_ID == ASIA* ]]; then
      fail "aws_session_token: argument emtpy and no default set"
    fi
  fi

  if [ -z "$AWS_SESSION_TOKEN" ]; then
    if [[ $AWS_ACCESS_KEY_ID == ASIA* ]]; then
      fail "aws_session_token: argument emtpy and no default set"
    fi
  fi


  # Derrivative
  WERCKER_DOCSET_PUBLISH_BUCKET_PARTS=($(split_by / $WERCKER_DOCSET_PUBLISH_BUCKET))
  WERCKER_DOCSET_PUBLISH_BUCKET_NAME=${WERCKER_DOCSET_PUBLISH_BUCKET_PARTS[0]}
  WERCKER_DOCSET_PUBLISH_BUCKET_PATH=$(join_by / ${WERCKER_DOCSET_PUBLISH_BUCKET_PARTS[@]:1})

  if [ -z "$WERCKER_DOCSET_PUBLISH_BUCKET_NAME" ]; then
    fail "bucket: could not extract the bucket name"
  fi


  # Docset Name and Version
  if [ -z "$WERCKER_DOCSET_PUBLISH_GEMSPEC" ]; then
    WERCKER_DOCSET_PUBLISH_NAME=$(basename $WERCKER_DOCSET_PUBLISH_DOCSET .docset)
    WERCKER_DOCSET_PUBLISH_VERSION=$(date +%Y%m%dT%H%M%S)
  else
    # Discover gem name and version from the gemspec
    WERCKER_DOCSET_PUBLISH_NAME=`ruby -r rubygems -e "puts Gem::Specification::load('$WERCKER_DOCSET_PUBLISH_GEMSPEC').name"`
    WERCKER_DOCSET_PUBLISH_VERSION=`ruby -r rubygems -e "puts Gem::Specification::load('$WERCKER_DOCSET_PUBLISH_GEMSPEC').version"`

    if [ -z "$WERCKER_DOCSET_PUBLISH_NAME" ]; then
      fail "could not determine name from the gemspec"
    fi

    if [ -z "$WERCKER_DOCSET_PUBLISH_VERSION" ]; then
      fail "could not determine version from the gemspec"
    fi
  fi

  WERCKER_DOCSET_PUBLISH_BASENAME="$WERCKER_DOCSET_PUBLISH_NAME-$WERCKER_DOCSET_PUBLISH_VERSION"


  # Package the Docset
  tar \
    -cvz \
    -f $WERCKER_DOCSET_PUBLISH_BASENAME.tgz \
    -C $(dirname $WERCKER_DOCSET_PUBLISH_DOCSET) \
    $(basename $WERCKER_DOCSET_PUBLISH_DOCSET)

  WERCKER_DOCSET_PUBLISH_URL=$(join_by / http:/ $WERCKER_DOCSET_PUBLISH_BUCKET_NAME.s3.amazonaws.com $WERCKER_DOCSET_PUBLISH_BUCKET_PATH $WERCKER_DOCSET_PUBLISH_BASENAME.tgz)

  cat <<EOF >$WERCKER_DOCSET_PUBLISH_NAME.xml
<entry>
  <version>$WERCKER_DOCSET_PUBLISH_VERSION</version>
  <url>$WERCKER_DOCSET_PUBLISH_URL</url>
</entry>
EOF

  # Publish the docset to S3
  (
    AWS_ACCESS_KEY_ID=$WERCKER_DOCSET_PUBLISH_AWS_ACCESS_KEY_ID
    AWS_SECRET_ACCESS_KEY=$WERCKER_DOCSET_PUBLISH_AWS_SECRET_ACCESS_KEY
    if [ ! -z $WERCKER_DOCSET_PUBLISH_AWS_SESSION_TOKEN ]; then
      AWS_SESSION_TOKEN=$WERCKER_DOCSET_PUBLISH_AWS_SESSION_TOKEN
    fi

    aws s3 cp \
      --sse \
      --acl public-read \
      $WERCKER_DOCSET_PUBLISH_BASENAME.tgz \
      s3://$WERCKER_DOCSET_PUBLISH_BUCKET/$WERCKER_DOCSET_PUBLISH_BASENAME.tgz

    aws s3 cp \
      --sse \
      --acl public-read \
      $WERCKER_DOCSET_PUBLISH_NAME.xml \
      s3://$WERCKER_DOCSET_PUBLISH_BUCKET/$WERCKER_DOCSET_PUBLISH_NAME.xml
  )
}

function split_by { local FS="$1"; shift; echo "${*//$FS/ }"; }
function join_by { local IFS="$1"; shift; echo "$*"; }

main
