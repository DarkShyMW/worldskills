Import-Module ActiveDirectory;

$name = "IT", "Manager", "Supporter", "Overal", "Cloud storage", "Competitors";

ForEach ($item in $name) {
    New-ADOrganizationalUnit -Name $item;
    New-ADGroup -Name $item -GroupScope Global -Path ("OU=" + $item + ",DC=skill39,DC=wsr");
}