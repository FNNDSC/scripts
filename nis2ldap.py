#
#
#

import sys

passwdFile = '/etc/passwd'
ypPasswdFile = '/tmp/yppasswd' # created with: ypcat passwd > /tmp/yppasswd

passwdEntries = {}
ypPasswdEntries = {}

# read files

pF = open( passwdFile, 'r' )
yF = open( ypPasswdFile, 'r' )

for l in pF:
  # line by line
  splitted = l.split( ':' )
  username = splitted[0]

  # save line in hashmap
  passwdEntries[username] = l

pF.close()

for l  in yF:
  # line by line
  splitted = l.split( ':' )
  username = splitted[0]

  # save line in hashmap
  ypPasswdEntries[username] = l

yF.close()

# sanity check
allUsers = set( passwdEntries ).intersection( set( ypPasswdEntries ) )
if len( allUsers ) != len( ypPasswdEntries ):
  print 'Error: parsing went wrong - aborting..'
  sys.exit()

output = ''

# loop through allUsers (already filtered out system accounts etc.)
for u in allUsers:
  # example entry
  # ypcat passwd
  #   testuser:$1$E5LgItYR$etGVyMFVJlJPeTiy3tDBr0:9950:9950:Test User:/chb/users/testuser:/bin/bash
  # 
  # /etc/passwd
  #   testuser:*:9950:9950:Test User:/chb/users/testuser:/bin/bash
  currentPasswd = passwdEntries[u]
  currentYpPasswd = ypPasswdEntries[u]
  currentP = currentPasswd.split( ':' )
  currentY = currentYpPasswd.split( ':' )

  #
  # we need something like this
  #  dn: uid=Daniel.Haehn,ou=people,dc=fnndsc
  #  givenName: Daniel
  #  sn: Haehn
  #  cn: Daniel Haehn
  #  uid: Daniel.Haehn
  #  uidNumber: 1122
  #  gidNumber: 1102
  #  homeDirectory: /chb/users/Daniel.Haehn
  #  loginShell: /bin/bash
  #  objectClass: inetOrgPerson
  #  objectClass: posixAccount
  #  userPassword: YWJj

  # the following is fixed (for convenience)
  gid = '1102'
  shell = '/bin/bash'

  dn = 'dn: uid=' + u + ',ou=people,dc=fnndsc'
  givenName = 'givenName: ' + currentP[4].partition( ' ' )[0]

  lastName = currentP[4].partition( ' ' )[2]
  if lastName == "":
    lastName = 'X'

  sn = 'sn: ' + lastName # index 1 is the space
  cn = 'cn: ' + currentP[4].partition( ' ' )[0] + ' ' + lastName
  uid = 'uid: ' + u
  uidNumber = 'uidNumber: ' + str( currentP[2] )
  gidNumber = 'gidNumber: ' + str( gid )
  homeDirectory = 'homeDirectory: /chb/users/' + u
  loginShell = 'loginShell: ' + shell
  objectClass = 'objectClass: inetOrgPerson'
  objectClass2 = 'objectClass: posixAccount'
  userPassword = 'userPassword: {crypt}' + currentY[1]

  # put it all together
  output += dn + '\n'
  output += givenName + '\n'
  output += sn + '\n'
  output += cn + '\n'
  output += uid + '\n'
  output += uidNumber + '\n'
  output += gidNumber + '\n'
  output += homeDirectory + '\n'
  output += loginShell + '\n'
  output += objectClass + '\n'
  output += objectClass2 + '\n'
  output += userPassword + '\n'

  # some empty lines
  output += '\n\n'

print output
