# Set file and folder names
$LayoutPath = "C:\intune\Start-Menu"
$LayoutXMLFile = "Layout2.xml"
$StartAppsFile = "StartApps.csv"
$PublisherIDsFile = "PublisherIDs.txt"
$Taskbarlayout = "taskbar.txt"
$TaskbarAppsCSV

# Set the output location of the layout xml file
$XmlPath = "$LayoutPath\$LayoutXMLFile"

# Get the text files containing groups of apps to be pinned
# The files must be named GROUPNAME.1 and GROUPNAME.2
# where GROUPNAME = the desired display name of the group in the start menu
$GroupFiles = Get-ChildItem -Path $LayoutPath\* -Include *.1, *.2

# Get the Name (file name + extension) and BaseName (file name only) properties of the group files 
$Group1 = $GroupFiles | Where-Object {$_.Name -match ".1"} | Select-Object -Property Name,BaseName
$Group2 = $GroupFiles | Where-Object {$_.Name -match ".2"} | Select-Object -Property Name,BaseName
#$Taskbarlayout1 = = $TaskbarLayout | Where-Object {$_.Name -match ".txt"} | Select-Object -Property Name,BaseName
function WriteShellXML {
    
    # Write the required XML elements for the Start layout file
    $writer.WriteStartElement("LayoutModificationTemplate", "http://schemas.microsoft.com/Start/2014/LayoutModification")  
    $writer.WriteAttributeString("Version", "1")

    $writer.WriteStartElement("DefaultLayoutOverride")
    $writer.WriteAttributeString("LayoutCustomizationRestrictionType", "OnlySpecifiedGroups")

    $writer.WriteStartElement("StartLayoutCollection")

    $writer.WriteStartElement("defaultlayout", "StartLayout", "http://schemas.microsoft.com/Start/2014/FullDefaultLayout")
    $writer.WriteAttributeString("GroupCellWidth", "6")
    $writer.WriteStartElement("taskbar", "taskbarlayout", "http://schemas.microsoft.com/Start/2014/TaskbarLayout")
    
}
function writeTaskbarShellXML{ 
   
    
    $writer.WriteStartElement("defaultlayout", "TaskbarLayout", "http://schemas.microsoft.com/Start/2014/TaskbarLayout")


    $writer.WriteStartElement("taskbar", "taskbarlayout", "http://schemas.microsoft.com/Start/2014/TaskbarLayout")}
function WriteTileXML ($Group) {
    
    switch ($Group) {

        1 {$GroupNumber = $Group1}
        2 {$GroupNumber = $Group2}
    }
    
    # Get the list of apps for the designated group
    $GroupApps = Get-Content -Path $LayoutPath\$($GroupNumber.Name)

    # Set the group name to be displayed in the Start Menu
    $StartGroupName = $GroupNumber.BaseName

    # Write the Start Group XML Element
    $writer.WriteStartElement("start", "Group", "http://schemas.microsoft.com/Start/2014/StartLayout")
    $writer.WriteAttributeString("Name", $StartGroupName)

    # Set loop counter
    $Counter = 0

    # Loop through the group apps list and write corresponding XML elements
    foreach ($Item in $GroupApps) {

        # Get the start app info for the pinned list item
        $StartApp = $StartAppsCSV | Where-Object {$_.Name -eq $Item}
   
        # Check for existence of start app
        if ($StartApp) {

            # Determine modern or desktop app, set corresponding tile and appID types
            if (($PubIDs | ForEach-Object {$StartApp.AppID -match $_} ) -contains $true) {

                $TileType = "Tile"
                $AppIDType = "AppUserModelID"
            }
            else {

                $TileType = "DesktopApplicationTile"
                $AppIDType = "DesktopApplicationID"
            }
        
            # Determine column and row value of the tile
            switch ($Counter) {

                0 {$column = 0; $row = 0}
                1 {$column = 2; $row = 0}
                2 {$column = 4; $row = 0}
                3 {$column = 0; $row = 2}
                4 {$column = 2; $row = 2}
                5 {$column = 4; $row = 2}
                6 {$column = 0; $row = 4}
                7 {$column = 2; $row = 4}
                8 {$column = 4; $row = 4}
            }
        
            # Write XML elements and attributes for the tile
            $writer.WriteStartElement("start", $TileType, "http://schemas.microsoft.com/Start/2014/StartLayout")
            $writer.WriteAttributeString("Size", "2x2")
            $writer.WriteAttributeString("Column", $column)
            $writer.WriteAttributeString("Row", $row)
            $writer.WriteAttributeString($AppIDType, $StartApp.AppID)
            $writer.WriteEndElement()
        
            # Increment loop counter
            $Counter++ 
        }
    }            
}
# If Group 1 exists, proceed. Else, do nothing
if ($Group1) {

    # Get Start Apps list
    $StartAppsCSV = Import-Csv -Path $LayoutPath\$StartAppsFile
    
    # Get Modern App publisher IDs
    $PubIDs = Get-Content -Path $LayoutPath\$PublisherIDsFile

    # Create a new XML writer settings object and configure settings 
    $settings = New-Object system.Xml.XmlWriterSettings 
    $settings.Indent = $true 
    $settings.OmitXmlDeclaration = $true

    # Create a new XML writer 
    $writer = [system.xml.XmlWriter]::Create($XmlPath, $settings)

    # Call function to write XML shell
    WriteShellXML
  #  writeTaskbarShellXML
    
    # Call function to write tile XML elements
    WriteTileXML -Group 1

    # Only executed if Group 2 exists
    if ($Group2) {
        
        # Write additional end element for Group 1
        $writer.WriteEndElement()

        WriteTileXML -Group 2
    }
    

}

function WriteTaskBarXML ($TaskBarlayout) {
    
  
    
    # Get the list of apps for the designated group
    $GroupApps = Get-Content -Path $LayoutPath\$($taskbarlayout)


    # Write the taskbar XML Element
    $writer.WriteStartElement("taskbar", "http://schemas.microsoft.com/Start/2014/TaskbarLayout")
    $writer.WriteAttributeString("Taskbar", "TaskbarPinList")

    # Set loop counter
    $Counter = 0

    # Loop through the group apps list and write corresponding XML elements
    foreach ($Item in $GroupApps) {

        # Get the start app info for the pinned list item
        $StartApp = $StartAppsCSV | Where-Object {$_.Name -eq $Item}
   
        # Check for existence of start app
        if ($StartApp) {

            # Determine modern or desktop app, set corresponding tile and appID types
            if (($PubIDs | ForEach-Object {$StartApp.AppID -match $_} ) -contains $true) {

                $TileType = "UWA"
                $AppIDType = "AppUserModelID"
            }
            else {

                $TileType = "DesktopApp"
                $AppIDType = "DesktopApplicationID"
            }
        

        
# Write XML elements and attributes for the tile
            $writer.WriteStartElement("taskbar", $TileType, "http://schemas.microsoft.com/Start/2014/TaskbarLayout")
            $writer.WriteAttributeString($AppIDType, $StartApp.AppID)
            $writer.WriteEndElement()
        
            # Increment loop counter
            $Counter++ 
        }
    }            
}
# If taskbar exists, proceed. Else, do nothing
if ($TaskbarLayout) {

    # Get Start Apps list
    $StartAppsCSV = Import-Csv -Path $LayoutPath\$StartAppsFile
    
    # Get Modern App publisher IDs
    $PubIDs = Get-Content -Path $LayoutPath\$PublisherIDsFile

    # Create a new XML writer settings object and configure settings 
    $settings = New-Object system.Xml.XmlWriterSettings 
    $settings.Indent = $true 
    $settings.OmitXmlDeclaration = $true

    # Create a new XML writer 
    $writer = [system.xml.XmlWriter]::Create($XmlPath, $settings)

    # Call function to write XML shell
    #WriteTaskbarShellXML
    
    # Call function to write tile XML elements
    WriteTaskBarXML $TaskBarlayout
    
    # Flush the XML writer and close the file     
    $writer.Flush() 
    $writer.Close()
}
