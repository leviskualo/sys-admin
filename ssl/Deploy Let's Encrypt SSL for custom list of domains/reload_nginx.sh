#!/bin/sh

echo "Attempting to reload Nginx configuration...";
nginx -t > /dev/null 2>&1
nginxresult=$?
if [ $nginxresult -eq 0 ];
then
    service nginx reload
else
    echo "Nginx config test failed. Please investigate!";
    exit 1;
fi
[root@web1 bin]#
[root@web1 bin]#
[root@web1 bin]#
[root@web1 bin]#
[root@web1 bin]#
[root@web1 bin]#
[root@web1 bin]#
[root@web1 bin]#
[root@web1 bin]#
[root@web1 bin]#
[root@web1 bin]#
[root@web1 bin]#
[root@web1 bin]#
[root@web1 bin]#
[root@web1 bin]#
[root@web1 bin]#
[root@web1 bin]#
[root@web1 bin]# cat reload_nginx.sh
#!/bin/sh

echo "Attempting to reload Nginx configuration...";
nginx -t > /dev/null 2>&1
nginxresult=$?
if [ $nginxresult -eq 0 ];
then
    service nginx reload
else
    echo "Nginx config test failed. Please investigate!";
    exit 1;
fi