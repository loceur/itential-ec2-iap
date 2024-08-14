SSM_PATH="/ec2/ips-03cd2d6d"
ips_csv="`aws ssm get-parameter --name "${SSM_PATH}" | jq .Parameter.Value | sed -e 's/"//g'`"
ips=($(echo $ips_csv $| tr "," "\n"))

echo ${ips[0]}

cat <<EOF > output
ansible_host: `echo ${ips[0]}`
EOF
