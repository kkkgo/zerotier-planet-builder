#!/usr/bin/env sh

if  [ -z "$ZU_SECURE_HEADERS"  ]
then export ZU_SECURE_HEADERS=false
fi

if  [ -z "$ZU_DEFAULT_USERNAME"  ]
then export ZU_DEFAULT_USERNAME=admin
fi

if  [ -z "$ZU_DEFAULT_PASSWORD"  ]
then export ZU_DEFAULT_PASSWORD=zero-ui
fi

cp /var/lib/zerotier-one/planet /app/frontend/build/planet
js=$(grep -ors "Please Log In to continue" /app|cut -d":" -f1)
sed -i "s/Please Log In to continue/\/app\/planet /g" $js
sed -i "s/ZeroUI - ZeroTier Controller Web UI - is a web user interface for a self-hosted ZeroTier network controller./Download planet:/g"  $js
echo Run zerotier...
zerotier-one -d
cd /app/backend/
echo Run zero ui...
node ./bin/www
