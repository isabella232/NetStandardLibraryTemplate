<#
.SYNOPSIS
    A global find/replace to rename a library, including in source files and file/folder names.
.DESCRIPTION
    Finds all files and folders containing the old library name and renames them with the new library name.
    Finds all occurences of old library name in source and project files and replaces with new library name.
.PARAMETER OldLibraryName
    The old library name in PascalCase (ex: "MyOldLibraryName")
.PARAMETER NewLibraryName
    The new library name in PascalCase (ex: "MyNewLibraryName")
.PARAMETER OldCompanyName
    (Optional) The old company name in PascalCase (ex: "MyOldCompanyName").
    Note that company name is just used in the sample apps.
.PARAMETER NewCompanyName
    (Optional) The new company name in PascalCase (ex: "MyNewCompanyName").
    Note that company name is just used in the sample apps.
.EXAMPLE
    C:\PS> RenameLibrary.ps1 -OldLibraryName "MyAwesomeLibrary" -NewLibraryName "MyActualLibraryName"
.NOTES
    Author: Wes Peter
    Date:   August 10, 2017
#>
Param(
    [Parameter(Mandatory = $True, Position = 1)]
    [string]$OldLibraryName,

    [Parameter(Mandatory = $True, Position = 2)]
    [string]$NewLibraryName,

    [Parameter(Mandatory = $False)]
    [string]$OldCompanyName,

    [Parameter(Mandatory = $False)]
    [string]$NewCompanyName
)

$ErrorActionPreference = "Stop"

# don't want to change file encodings while doing our find/replace so need this little
# helper to find the file encodings.  Based on https://stackoverflow.com/a/9121679
function Get-FileEncoding
{
    param ( [string] $FilePath )

    [byte[]] $byte = get-content -Encoding byte -ReadCount 4 -TotalCount 4 -Path $FilePath

    if ( $byte[0] -eq 0xef -and $byte[1] -eq 0xbb -and $byte[2] -eq 0xbf )
    { $encoding = 'UTF8' }
    elseif ($byte[0] -eq 0xfe -and $byte[1] -eq 0xff)
    { $encoding = 'BigEndianUnicode' }
    elseif ($byte[0] -eq 0xff -and $byte[1] -eq 0xfe)
    { $encoding = 'Unicode' }
    elseif ($byte[0] -eq 0 -and $byte[1] -eq 0 -and $byte[2] -eq 0xfe -and $byte[3] -eq 0xff)
    { $encoding = 'UTF32' }
    elseif ($byte[0] -eq 0x2b -and $byte[1] -eq 0x2f -and $byte[2] -eq 0x76)
    { $encoding = 'UTF7'}
    else
    { $encoding = 'ASCII' }
    return $encoding
}

# first replace the folder and file names
Write-Host "Renaming any files or folders containing the name $OldLibraryName, replacing with name $NewLibraryName";
Get-Childitem  -Recurse |
    Sort-Object FullName -Descending |
    Where-Object {  $_.Name -match $OldLibraryName} |
    ForEach-Object {
        $oldName = $_.Name;
        $newName = $oldName.Replace($OldLibraryName, $NewLibraryName);
        Rename-Item $_.FullName $newName;
        Write-Host -ForegroundColor Green "Renamed $oldName to $newName";
    }


# replace strings inside files
Write-Host "Replacing $OldLibraryName with $NewLibraryName";

if ($NewCompanyName -and $OldCompanyName)
{
    Write-Host "Replacing $OldCompanyName with $NewCompanyName";
}
else
{
    Write-Host -ForegroundColor Yellow "'NewCompanyName' and 'OldCompanyName' not set so not replacing those"
    $NewCompanyName = "";
    $OldCompanyName = "";
}

Get-Childitem -File -Recurse | ForEach-Object {
    $file = $_.FullName;

    $fileContent = Get-Content -Raw $file;
    if ($fileContent.Contains($OldLibraryName) -or ($OldCompanyName -and $fileContent.Contains($OldCompanyName)))
    {
        $encoding = Get-FileEncoding $file;
        $fileContent.Replace($OldLibraryName, $NewLibraryName).`
            Replace($OldLibraryName.ToLower(), $NewLibraryName.ToLower()).`
            Replace($OldCompanyName.ToLower(), $NewCompanyName.ToLower()) |
            Set-Content $file -NoNewline -Encoding $encoding;
    }
}
