#!/bin/bash
### Set Language
TEXTDOMAIN=virtualhost

### Set default parameters
action=$1

#!/bin/bash

ARRAY=( "tul.sakilu.com:/home/ubuntu/vghtpe/public/"
        "multivendor.sakilu.com:/home/ubuntu/multivendor/"
        "sqladmin.sakilu.com:/home/ubuntu/sqladmin/"
      )

docker_string="docker run --name server -itd -p 80:80 -p 9000:9000"


for sites in "${ARRAY[@]}" ; do
    domain="${sites%%:*}"
    rootDir="${sites##*:}"

    owner=$(who am i | awk '{print $1}')
    email='sakilu@gmail.com'
    sitesAvailable='/home/ubuntu/docker/sites-enabled/'
    userDir=''
    sitesAvailabledomain=$sitesAvailable$domain.conf

    ### don't modify from here unless you know what you are doing ####

    if [ "$(whoami)" != 'root' ]; then
        echo $"You have no permission to run $0 as non-root user. Use sudo"
            exit 1;
    fi

    if [ "$action" != 'create' ] && [ "$action" != 'delete' ]
        then
            echo $"You need to prompt for action (create or delete) -- Lower-case only"
            exit 1;
    fi

    while [ "$domain" == "" ]
    do
        echo -e $"Please provide domain. e.g.dev,staging"
        read domain
    done

    if [ "$rootDir" == "" ]; then
        rootDir=${domain//./}
    fi

    ### if root dir starts with '/', don't use /var/www as default starting point
    if [[ "$rootDir" =~ ^/ ]]; then
        userDir=''
    fi

    webRootDir=$userDir$rootDir
    mappingDir="${webRootDir//public//}"


    if [ "$action" == 'create' ]
        then
            docker_string="$docker_string -v $mappingDir:$mappingDir"
            ### check if domain already exists
            if [ -e $sitesAvailabledomain ]; then
                echo -e $"This domain already exists.\nPlease Try Another one"
                exit;
            fi

            ### check if directory exists or not
            if ! [ -d $mappingDir ]; then
                ### create the directory
                mkdir $mappingDir
                ### give permission to root dir
                chmod 755 $mappingDir
                ### write test file in the new domain dir
                if ! echo "<?php echo phpinfo(); ?>" > $mappingDir/phpinfo.php
                then
                    echo $"ERROR: Not able to write in file $mappingDir/phpinfo.php. Please check permissions"
                    exit;
                else
                    echo $"Added content to $mappingDir/phpinfo.php"
                fi
            fi

            ### create virtual host rules file
            if ! echo "
            <VirtualHost *:80>
                ServerAdmin $email
                ServerName $domain
                ServerAlias $domain
                DocumentRoot $webRootDir
                <Directory />
                    AllowOverride All
                </Directory>
                <Directory $webRootDir>
                    Options Indexes FollowSymLinks MultiViews
                    AllowOverride all
                    Require all granted
                </Directory>
                ErrorLog $mappingDir$domain-error.log
                LogLevel error
                CustomLog $mappingDir$domain-access.log combined
            </VirtualHost>" > $sitesAvailabledomain
            then
                echo -e $"There is an ERROR creating $domain file"
                exit;
            else
                echo -e $"\nNew Virtual Host Created\n"
            fi

            ### Add domain in /etc/hosts
            if ! echo "127.0.0.1	$domain" >> /etc/hosts
            then
                echo $"ERROR: Not able to write in /etc/hosts"
                exit;
            else
                echo -e $"Host added to /etc/hosts file \n"
            fi

            if [ "$owner" == "" ]; then
                chown -R $(whoami):$(whoami) $rootDir
            else
                chown -R $owner:$owner $rootDir
            fi

            ### show the finished message
            echo -e $"Complete! \nYou now have a new Virtual Host \nYour new host is: http://$domain \nAnd its located at $rootDir"
        else
            ### check whether domain already exists
            if ! [ -e $sitesAvailabledomain ]; then
                echo -e $"This domain does not exist.\nPlease try another one"
                exit;
            else
                ### Delete domain in /etc/hosts
                newhost=${domain//./\\.}
                sed -i "/$newhost/d" /etc/hosts

                ### Delete virtual host rules files
                rm $sitesAvailabledomain
            fi

            ### show the finished message
            echo -e $"Complete!\nYou just removed Virtual Host $domain"
    fi
done

if [ "$action" == 'create' ]
        then
            pwd=$(pwd)
            docker_string="$docker_string -v $pwd/sites-enabled/:/etc/apache2/sites-enabled/ 7a8f7e9a1e52 sudo  /usr/sbin/apache2ctl -D FOREGROUND"
            #docker_string="$docker_string -v $pwd/sites-enabled/:/etc/apache2/sites-enabled/ b0d14c8e0bcd sudo /bin/bash"
            echo -e $"$docker_string"
            eval $docker_string
        else
            docker stop server
            docker rm server
fi

