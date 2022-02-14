#Sorry, I'm newbie script kiddy
#Fix my errors, please
Import-Module ActiveDirectory
Import-Csv C:\users.csv -Delimiter ";" | ForEach-Object {New-ADUser -Name ($_."Last Name" + $_."First Name")  `
                                         -GivenName $_."First Name"                 `
                                         -Surname $_."Last Name"                   `
                                         -Title $_.Role                   `
                                         -MobilePhone $_.Phone            `
                                         -Department $_.OU                `
                                         -StreetAddress $_.Street         `
                                         -PostalCode $_.ZIP               `
                                         -City $_.City                    `
                                         -Country RU                      `
                                         -Path ("OU=" + $_.OU + ",DC=skill39,DC=wsr") `
                                         -AccountPassword(ConvertTo-SecureString("P@ssw0rd1") -AsPlainText -Force) `
                                         -Enabled $true                    `
                                         -CannotChangePassword $true}
Import-Csv C:\users.csv -Delimiter ";" | ForEach-Object{Add-ADGroupMember -Identity $_.OU `
                                         -Members ($_."Last Name" + $_."First Name") }