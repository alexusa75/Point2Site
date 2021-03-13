#######################################################################################################
#                                                                                                     #
# Name:        Azure Point to Site VPN.ps1                                                            #
#                                                                                                     #
# Version:     1.0                                                                                    #
#                                                                                                     #
# Description: Whit this script you will be able to configure a Point to Site VPN on Azure(ARM)       #
#			                                                                                          #
#                                                                                                     #
# Author:        Alexander Hurtado                                                                    #
# Collaboration: Carlos Teixeria                                                                      #
#                                                                                                     #
#                                                                                                     #
# Disclaimer: WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT					  #
#			  LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS					  #
#			  FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR                  #
#			  RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.								  #
#																									  #
#			                                                                        				  #
#																									  #
#######################################################################################################


#vaidate AzureRM Module
$RM = (Get-InstalledModule -Name Az).Version
[void] [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")

If(!$RM){
    $IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
    Write-Host " It's required to install Az module " -ForegroundColor Red
    $textNoInstall = " You have to install Az module, do you want me to do it for you "
    $NoAzureRM = [Microsoft.VisualBasic.Interaction]::MsgBox($textNoInstall,'YesNo,Question',"Use other credentials")
    Switch($NoAzureRM){
        Yes{
            If(-not $IsAdmin){
                Start-Process powershell -verb runas -argument {Install-Module -Name AzureRM -AllowClobber -Force:$true} -ErrorAction SilentlyContinue
            }Else{
                #Install-Module PowerShellGet -Force:$true
                Install-Module -Name Az -Repository PSGallery -AllowClobber -Force:$true
            }
            Write-Host "We've installed the Az module successfully" -ForegroundColor Blue -BackgroundColor White
         }
        No{
            Write-Host "Install the Module by yourself and after that run the script again " -ForegroundColor Yellow -BackgroundColor Red
            exit
            }
    }
}

#Creating the GUI

$inputXML = @"
<Window x:Class="MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WpfApplication2"
        mc:Ignorable="d"
        Title="Setup Self-Signed Certificate VPN Point to Site" Height="600.783" Width="998.498">
    <Grid Margin="0,2,0,0" Background="#FFCACFE4">
        <Grid.RowDefinitions>
            <RowDefinition Height="103*"/>
            <RowDefinition Height="231*"/>
            <RowDefinition Height="123*"/>
            <RowDefinition Height="146*"/>
        </Grid.RowDefinitions>
        <Label x:Name="label_Main" Content="Setup a Self-Signed Certificate for Point to Site VPN" HorizontalAlignment="Center" Height="33" Margin="46,24,46,0" VerticalAlignment="Top" Width="898" FontSize="16" HorizontalContentAlignment="Center" Foreground="White" FontWeight="Bold" Background="#FF5E46F1"/>
        <Button x:Name="button_Connect" Content="Connect to Azure" HorizontalAlignment="Left" Height="31" Margin="374,62,0,0" VerticalAlignment="Top" Width="238" FontWeight="Bold" FontSize="16" Background="#FF18EA5B"/>
        <Label x:Name="label_SelectSubscription" Content="Select Azure Subscription:" HorizontalAlignment="Left" Margin="54,43,0,0" VerticalAlignment="Top" FontSize="13.333" FontWeight="Bold" Width="177" HorizontalContentAlignment="Right" Grid.Row="1" Height="28"/>
        <TextBox x:Name="textBox_AddressPool" HorizontalAlignment="Left" Height="23" Margin="682,89,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="195" FontSize="13.333" Grid.Row="1"/>
        <Label x:Name="label_AddressPool" Content="VPN Client Address Pool:" HorizontalAlignment="Left" Margin="499,86,0,0" VerticalAlignment="Top" FontSize="13.333" FontWeight="Bold" Width="165" HorizontalContentAlignment="Right" Grid.Row="1" Height="28"/>
        <Label x:Name="label_taskAttributes" Content="Azure Parameters" HorizontalAlignment="Left" Margin="46,9,0,0" VerticalAlignment="Top" FontSize="14.667" FontWeight="Bold" Background="#FF1ABCF9" Width="898" HorizontalContentAlignment="Center" Height="30" Grid.Row="1"/>
        <Label x:Name="label_BatchAttributes" Content="Certificates Parameters" HorizontalAlignment="Left" Margin="46,160,0,0" VerticalAlignment="Top" FontSize="14.667" FontWeight="Bold" Background="#FF1ABCF9" Width="898" HorizontalContentAlignment="Center" Grid.Row="1" Height="30"/>
        <GroupBox x:Name="groupBox_Task2" Header="" HorizontalAlignment="Left" Height="161" Margin="47,95,0,0" VerticalAlignment="Top" Width="898" FontSize="14.667" FontWeight="Bold" Foreground="#FF092891" BorderBrush="#FF1635F9" Grid.RowSpan="2">
            <Button x:Name="Button_CIDR" Content="Check VNet and VNet Peer CIDR for overlap" HorizontalAlignment="Left" Height="22" Margin="629,99,0,0" VerticalAlignment="Top" Width="248" FontSize="10"/>
        </GroupBox>
        <Button x:Name="button_outputpath" Content="Path" HorizontalAlignment="Left" Height="27" Margin="881,212,0,0" Grid.Row="1" VerticalAlignment="Top" Width="56" FontWeight="Bold" Grid.RowSpan="2"/>
        <ComboBox x:Name="comboBox_AzureSubscription" HorizontalAlignment="Left" Margin="236,47,0,0" VerticalAlignment="Top" Width="249" FontSize="13.333" Grid.Row="1" Height="24" Grid.Column="2"/>
        <Label x:Name="label_SelectResourceGroup" Content="Select Resouce Group:" HorizontalAlignment="Left" Margin="54,82,0,0" VerticalAlignment="Top" FontSize="13.333" FontWeight="Bold" Width="177" HorizontalContentAlignment="Right" Grid.Row="1" Height="28"/>
        <ComboBox x:Name="comboBox_SelectResourceGroup" HorizontalAlignment="Left" Margin="236,86,0,0" VerticalAlignment="Top" Width="249" FontSize="13.333" Grid.Row="1" Height="24"/>
        <Label x:Name="label_SelectGateWay" Content="Select Gateway:" HorizontalAlignment="Left" Margin="499,43,0,0" VerticalAlignment="Top" FontSize="13.333" FontWeight="Bold" Width="165" HorizontalContentAlignment="Right" Grid.Row="1" Height="28"/>
        <ComboBox x:Name="comboBox_SelectGateWay" HorizontalAlignment="Left" Margin="682,49,0,0" VerticalAlignment="Top" Width="249" FontSize="13.333" Grid.Row="1" Height="24"/>
        <TextBox x:Name="textBox_rootname" HorizontalAlignment="Left" Height="23" Margin="233,216,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="242" FontSize="13.333" Text="RootCertAzure" Grid.Row="1" Grid.RowSpan="2"/>
        <Label x:Name="label_rootname" Content="Root Cert Name:" HorizontalAlignment="Left" Margin="80,212,0,0" VerticalAlignment="Top" FontSize="13.333" FontWeight="Bold" Width="126" HorizontalContentAlignment="Right" Grid.Row="1" Height="28" Grid.RowSpan="2"/>
        <TextBox x:Name="textBox_clientname" HorizontalAlignment="Left" Height="23" Margin="233,48,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="242" FontSize="13.333" Text="ClientCertAzure" Grid.Row="2"/>
        <Label x:Name="label_clientname" Content="Client Cert Name:" HorizontalAlignment="Left" Margin="80,43,0,0" VerticalAlignment="Top" FontSize="13.333" FontWeight="Bold" Width="126" HorizontalContentAlignment="Right" Grid.Row="2" Height="28"/>
        <TextBox x:Name="textBox_Path" HorizontalAlignment="Left" Height="23" Margin="682,214,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="194" FontSize="13.333" Grid.Row="1" Grid.RowSpan="2"/>
        <Label x:Name="label_path" Content="Output Path:" HorizontalAlignment="Left" Margin="529,210,0,0" VerticalAlignment="Top" FontSize="13.333" FontWeight="Bold" Width="126" HorizontalContentAlignment="Right" Grid.Row="1" Height="28" Grid.RowSpan="2"/>
        <Label x:Name="label_pfxpass" Content="Cert Pfx Password:" HorizontalAlignment="Left" Margin="514,43,0,0" VerticalAlignment="Top" FontSize="13.333" FontWeight="Bold" HorizontalContentAlignment="Right" Width="147" Grid.Row="2" Height="28"/>
        <PasswordBox x:Name="password_pfxpass" HorizontalAlignment="Left" Margin="682,47,0,0" VerticalAlignment="Top" Width="194" FontSize="13.333" Height="24" Grid.Row="2"/>
        <Button x:Name="buttom_DeleteCertOnpremise" Content="Delete the Certificates on premises" HorizontalAlignment="Left" Margin="631,37,0,0" VerticalAlignment="Top" Width="266" RenderTransformOrigin="0.5,0.5" Foreground="Black" Grid.Row="3" Height="28" FontSize="14.667" Background="#FF87D2E8">
            <Button.RenderTransform>
                <TransformGroup>
                    <ScaleTransform/>
                    <SkewTransform/>
                    <RotateTransform Angle="0.066"/>
                    <TranslateTransform/>
                </TransformGroup>
            </Button.RenderTransform>
        </Button>
        <Button x:Name="buttom_Exit" Content="Exit" HorizontalAlignment="Left" Margin="454,56,0,0" VerticalAlignment="Top" Width="107" RenderTransformOrigin="0.5,0.5" FontWeight="Bold" Grid.Row="3" Height="27" FontSize="14.667" Background="#FF9FA8E0">
            <Button.RenderTransform>
                <TransformGroup>
                    <ScaleTransform/>
                    <SkewTransform/>
                    <RotateTransform Angle="0.066"/>
                    <TranslateTransform/>
                </TransformGroup>
            </Button.RenderTransform>
        </Button>
        <Button x:Name="buttom_CreateCertOnpremise" Content="Create Certificate Root and Client" HorizontalAlignment="Left" Margin="145,37,0,0" VerticalAlignment="Top" Width="244" RenderTransformOrigin="0.5,0.5" Grid.Row="3" Height="27" FontSize="14.667" Background="#FF87D2E8">
            <Button.RenderTransform>
                <TransformGroup>
                    <ScaleTransform/>
                    <SkewTransform/>
                    <RotateTransform Angle="0.066"/>
                    <TranslateTransform/>
                </TransformGroup>
            </Button.RenderTransform>
        </Button>
        <Button x:Name="buttom_DeleteCertAzure" Content="Delete the Certificates on Azure" HorizontalAlignment="Left" Margin="631,71,0,0" VerticalAlignment="Top" Width="265" RenderTransformOrigin="0.5,0.5" Foreground="Black" Grid.Row="3" Height="31" FontSize="14.667" Background="#FF87D2E8">
            <Button.RenderTransform>
                <TransformGroup>
                    <ScaleTransform/>
                    <SkewTransform/>
                    <RotateTransform Angle="0.066"/>
                    <TranslateTransform/>
                </TransformGroup>
            </Button.RenderTransform>
        </Button>
        <Button x:Name="buttom_CreateCertAzure" Content="Set the Certificate on Azure" HorizontalAlignment="Left" Margin="144,71,0,0" VerticalAlignment="Top" Width="245" RenderTransformOrigin="0.5,0.5" Grid.Row="3" Height="26" FontSize="14.667" Background="#FF87D2E8">
            <Button.RenderTransform>
                <TransformGroup>
                    <ScaleTransform/>
                    <SkewTransform/>
                    <RotateTransform Angle="0.066"/>
                    <TranslateTransform/>
                </TransformGroup>
            </Button.RenderTransform>
        </Button>
        <GroupBox x:Name="groupBox" Header="" HorizontalAlignment="Left" Height="141" Margin="44,182,0,0" Grid.Row="1" Grid.RowSpan="2" VerticalAlignment="Top" Width="902" BorderBrush="#FF0F1EB6"/>
        <Button x:Name="button_AP" Content="Set" HorizontalAlignment="Left" Margin="884,91,0,0" Grid.Row="1" VerticalAlignment="Top" Width="47" FontWeight="Bold"/>
    </Grid>
</Window>
"@
$conn = $false
Remove-Variable WPF*
Add-Type -AssemblyName System.Windows.Forms
$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N'  -replace '^<Win.*', '<Window'
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML

$reader=(New-Object System.Xml.XmlNodeReader $xaml)
try{$FormMain=[Windows.Markup.XamlReader]::Load( $reader )}
catch{Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."}

$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name "WPF$($_.Name)" -Value $FormMain.FindName($_.Name)}

#Functions

Function enableface([bool]$ena){
    $WPFcomboBox_AzureSubscription.IsEnabled = $ena
    $WPFcomboBox_SelectGateWay.IsEnabled = $ena
    $WPFcomboBox_SelectResourceGroup.IsEnabled = $ena
    $WPFtextBox_AddressPool.IsEnabled = $ena
    $WPFbutton_AP.IsEnabled = $ena
    $WPFButton_CIDR.IsEnabled = $ena

}

Function validIpRange([string]$IpRange){
    ### Validate Ip range

    $iprangepattern = "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/([0-9]|[1-2][0-9]|3[0-2]))$"

    $valid = $IpRange -match $iprangepattern

    return $valid

}

enableface($false)

Function DeleteCerts
{
    Param(
        [String]
        $rootcert
    ,
        [String]
        $clitncert
    ,
        [Bool]
        $removefromcerdir
    ,
        [String]
        $txtfile
    )
    Process
    {
        If($rootcert){Remove-Item $rootcert}

        If($clitncert){Remove-Item $clitncert}

        If($txtfile){Remove-Item $txtfile}

        If($removefromcerdir){Get-ChildItem Cert:\CurrentUser\My |?{($_.Thumbprint -eq $cert.Thumbprint) -or ($_.Thumbprint -eq $clientcert.Thumbprint)}|Remove-Item}
        }
}

Function connect{

    Try{$valconnection = (Get-AzSubscription -ErrorAction SilentlyContinue).SubscriptionId}
    Catch{
        If($valconnection){
            Disconnect-AzAccount
        }
    }


    Try{
        Connect-AzAccount -ErrorAction SilentlyContinue
        $val = (Get-AzSubscription -ErrorAction SilentlyContinue).SubscriptionId
        If($val){
        $script:conn = $true
        $WPFcomboBox_AzureSubscription.IsEnabled = $true
        $WPFcomboBox_AzureSubscription.IsEnabled = $true
        Write-Host "Now you're connected to azure!" -ForegroundColor green -BackgroundColor black
        }
      }
    Catch{
        Write-Host "We couldn't connect with the provided credentials" -ForegroundColor Red -BackgroundColor Yellow
        }
}

Function CIRD
{
    Param(
        [String]
        $reso
    ,
        [String]
        $gateway
    )
    Process
    {
        $subnet = ((Get-AzVirtualNetworkGateway -Name $gateway -ResourceGroupName $reso -ErrorAction SilentlyContinue |select -ExpandProperty IpConfigurations).Subnet).Id
        $net = $subnet.Split("/")[8]


        $script:NetAddressSpace = ((Get-AzVirtualNetwork -ResourceGroupName $reso -Name $net).AddressSpace).AddressPrefixes
        $peertemp = @()
        $peertemp = (((Get-AzVirtualNetwork -ResourceGroupName $reso -Name $net -ErrorAction SilentlyContinue).VirtualNetworkPeerings).RemoteVirtualNetwork).Id

        If($peertemp){
            $peer = @()
            $NetAddressSpacePeer = ""
            $addressPeers = ""
            ForEach($pee in $peertemp){
                $peer = $pee.Split("/")[8]
                $res =  $pee.Split("/")[4]
                $NetAddressSpacePeer = ((Get-AzVirtualNetwork -ResourceGroupName $res -Name $peer).AddressSpace).AddressPrefixes
                $script:addressPeers += $NetAddressSpacePeer

            }

        }Else{$script:addressPeers = "N/A"}

    }
}


#Form event actions

$WPFbuttom_CreateCertAzure.IsEnabled = $false
$WPFbuttom_DeleteCertAzure.IsEnabled = $false
$WPFbuttom_DeleteCertOnpremise.IsEnabled = $false

$WPFbutton_Connect.Add_Click({
Try{
    If($WPFbutton_Connect.Content -eq "Disconnect from Azure"){
      $val = (Get-AzSubscription -ErrorAction SilentlyContinue).SubscriptionId
      If($val){
        Disconnect-AzAccount
        enableface($false)
        $WPFcomboBox_AzureSubscription.items.Clear()
        $WPFcomboBox_SelectResourceGroup.Items.Clear()
        $WPFcomboBox_SelectGateWay.Items.Clear()
        $WPFtextBox_AddressPool.Text = ""
        $WPFbutton_Connect.Content = "Connect to Azure"
        $WPFbutton_Connect.Background = "#FF18EA5B"
        Write-Host "Now you're disconnected! " -ForegroundColor Red -BackgroundColor Yellow
      }


    }Else{
        connect
        If($conn){
            $WPFbutton_Connect.Content = "Disconnect from Azure"
            $WPFbutton_Connect.Background = "#FFE28A8A"
            $substemp = ""
            $subscriptionIdandName = ""

            $substemp = Get-AzSubscription -ErrorAction SilentlyContinue |select Name, Subscriptionid
            $WPFcomboBox_AzureSubscription.items.Clear()
            If($substemp){
                ForEach($subb in $substemp){
                    $subscriptionIdandName = $subb.Name + "/" + $subb.Subscriptionid
                    [void]$WPFcomboBox_AzureSubscription.Items.Add($subscriptionIdandName)
                }
            }

            }
    }

}
Catch{}

})

$WPFcomboBox_AzureSubscription.Add_SelectionChanged({

    If($WPFcomboBox_AzureSubscription.SelectedItem){

       $script:subsId = ($WPFcomboBox_AzureSubscription.SelectedItem).split("/")[1]

       write-host "Getting Resources Groups with Virtual Network Gateway configured, please wait..." -ForegroundColor Yellow
       Select-AzSubscription $subsId
       $resourtemp = (Get-AzResourceGroup | ?{($_.ResourceId -like '*'+$subsId+'*') -and ($_.ResourceId -notlike '*RecoveryServices*')}).ResourceGroupName
       $resources = @()

       If($resourtemp){
            ForEach($rest in $resourtemp){
                $gatetemp = ""
                $gatetemp = (Get-AzVirtualNetworkGateway -ResourceGroupName $rest -ErrorAction SilentlyContinue).Name
                If($gatetemp){

                    [void]$WPFcomboBox_SelectResourceGroup.Items.Add($rest)
                }
            }

             $WPFcomboBox_SelectResourceGroup.IsEnabled = $true
             }
       }Else{
            Write-Host "There are not Resource Group with Virtual Network Gateway configured, you should create the Gateway by yourself and then run this script again" -ForegroundColor Yellow -BackgroundColor Red
            [void] [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")
            $textnogateway = " There are not Resource Group with Virtual Network Gateway configured, you should create the Gateway by yourself and then run this script again "
            $Nogateway = [Microsoft.VisualBasic.Interaction]::MsgBox($textnogateway,'OKOnly,Critical',"No Gateway Sorry")
            $FormMain.Close()

        }

})

$WPFcomboBox_SelectResourceGroup.Add_SelectionChanged({
    If($WPFcomboBox_SelectResourceGroup.SelectedItem){

       $script:ResourceName = $WPFcomboBox_SelectResourceGroup.SelectedItem
       $gatewayName = (Get-AzVirtualNetworkGateway -ResourceGroupName $ResourceName).Name
       $WPFcomboBox_SelectGateWay.IsEnabled = $true
       $WPFcomboBox_SelectGateWay.Items.Clear()
       ForEach($gat in $gatewayName){
         #[void]
         $WPFcomboBox_SelectGateWay.Items.Add($gat)
       }
    }
})

$WPFcomboBox_SelectGateWay.Add_SelectionChanged({
    If($WPFcomboBox_SelectGateWay.SelectedItem){
        $Gateway = Get-AzVirtualNetworkGateway -ResourceGroupName $ResourceName -Name $WPFcomboBox_SelectGateWay.SelectedItem
        $script:gatewayy = $Gateway.name
        $WPFtextBox_AddressPool.IsEnabled = $true
        $WPFbutton_AP.IsEnabled = $true
        $script:GateWay = $gatewayy
        $script:addressPrefix = (($Gateway.VpnClientConfiguration).VpnClientAddressPool).AddressPrefixes
        $WPFtextBox_AddressPool.Text = $addressPrefix
        $WPFButton_CIDR.IsEnabled = $true
    }

})

$WPFcomboBox_SelectGateWay.Items.Clear()

$WPFButton_CIDR.Add_Click({
    If($WPFcomboBox_SelectGateWay.SelectedItem){
        CIRD -reso $ResourceName -gateway $gatewayy
        $NetAddressSpace
        $addressPeers
        Write-Host "We're pulling information about your VNet and your Peers CIDR address, please wait..." -ForegroundColor Yellow

        $cidrtext = "Make sure the VPN Client Address Pool does not overlap with any of these VNet: " + $NetAddressSpace + "  Peers to VNet: " + $addressPeers + " ,or with any on-premises address spaces…"
        [Microsoft.VisualBasic.Interaction]::MsgBox($cidrtext,'OKOnly,Information',"Avoid overlab")
    }Else{
        Write-Host "No GateWay selected" -ForegroundColor Yellow -BackgroundColor Red
    }
})

$WPFbutton_outputpath.Add_Click({
Try{
    Add-Type -AssemblyName System.Windows.Forms
    $FileBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $FileBrowser.Description = "Select Output Folder"
    [void]$FileBrowser.ShowDialog()
    $script:path = $FileBrowser.SelectedPath
    $WPFtextBox_Path.text = $path

}
Catch{

     }
})

$WPFbuttom_CreateCertOnpremise.Add_Click({
    If($WPFtextBox_rootname.Text -and $WPFtextBox_clientname.Text -and $WPFtextBox_Path.Text -and $WPFpassword_pfxpass.Password){

        #Create the Certificates Root and Client
        Write-Host "We're creating the certificates" -ForegroundColor Yellow
        $FormMain.Cursor = "Wait"

        $rootname = "CN=" + $WPFtextBox_rootname.Text
        $clientname = "CN=" + $WPFtextBox_clientname.Text

        $script:cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature -Subject $rootname -KeyExportPolicy Exportable -HashAlgorithm sha256 -KeyLength 2048 -CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign

        $script:clientcert = New-SelfSignedCertificate -Type Custom -KeySpec Signature -Subject $clientname -KeyExportPolicy Exportable -HashAlgorithm sha256 -KeyLength 2048 -CertStoreLocation "Cert:\CurrentUser\My" -Signer $cert -TextExtension @("2.5.29.37 ={text}1.3.6.1.5.5.7.3.2")


        #Export the Root to 64Base Certificate

        $certToConvert = Get-ChildItem Cert:\CurrentUser\My |?{$_.Thumbprint -eq $cert.Thumbprint}

        $script:certFile = $WPFtextBox_Path.Text + "\" + $WPFtextBox_rootname.Text + "_64Base.cer"
        $script:txtfile = $WPFtextBox_Path.Text + "\PublicCertificateData.txt"

        $content = @(
            '-----BEGIN CERTIFICATE-----'
            [System.Convert]::ToBase64String($certToConvert.RawData, 'InsertLineBreaks')
            '-----END CERTIFICATE-----'
        )

        [string]$script:azureCert = [System.Convert]::ToBase64String($certToConvert.RawData) # 'InsertLineBreaks')
        $azureCert>$txtfile

        $content | Out-File -FilePath $certFile -Encoding ascii

        #Create the pfx Certificate in order to be installed on client vpn users

        $script:certFilepfx = $WPFtextBox_Path.Text + "\" + "Pfx_To_Install_Clients.pfx"

        $certclientexport = "Cert:\CurrentUser\My\" + $clientcert.Thumbprint

        $pfxpass = $WPFpassword_pfxpass.Password
        $pwd = ConvertTo-SecureString -String $pfxpass -Force -AsPlainText
        Export-PfxCertificate -cert $certclientexport -FilePath $certFilepfx -Password $pwd
        $WPFbuttom_CreateCertAzure.IsEnabled = $true
        $WPFbuttom_DeleteCertAzure.IsEnabled = $false
        $WPFbuttom_DeleteCertOnpremise.IsEnabled = $true
        $WPFbuttom_CreateCertOnpremise.IsEnabled = $false

        $FormMain.Cursor = "Arrow"

        $testNo64bit = " You've created the Root and Client Certificate, in the opened folder you will see the 64Base and pfx certificates "
        $NoAzure = [Microsoft.VisualBasic.Interaction]::MsgBox($testNo64bit,'OKOnly,Information',"The Certificates were created")
        explorer $WPFtextBox_Path.Text
  }Else{
    Write-Warning "All Certificate parameters are required"
    $testNo64bit = " All Certificate parameters are required "
    $NoAzure = [Microsoft.VisualBasic.Interaction]::MsgBox($testNo64bit,'OkOnly,Critical,SystemModal,Exclamation',"Create Cert Requirement")

  }

}
)

$WPFbuttom_CreateCertAzure.Add_Click({
    If($WPFcomboBox_AzureSubscription.SelectedItem -and $WPFcomboBox_SelectResourceGroup.SelectedItem -and $WPFcomboBox_SelectGateWay.SelectedItem -and $WPFtextBox_AddressPool.Text){
        Write-Host "We're creating the certificate on Azure VPN, It can takes several minutes, please wait" -ForegroundColor Yellow
        $FormMain.Cursor = "Wait"
        $radiusserver = ""
        $radiusserver = ((Get-AzVirtualNetworkGateway -ResourceGroupName $ResourceName -Name $Gateway -ErrorAction SilentlyContinue).VpnClientConfiguration).RadiusServerAddress
        If(!$radiusserver){
            $script:P2SRootCertName = "AzureCert_" + [DateTime]::Now.ToString("yyyyMMdd-HHmmss")
            $p2srootcert = New-AzVpnClientRootCertificate -Name $P2SRootCertName -PublicCertData $azureCert
            $GateWayforVPN = $WPFcomboBox_SelectGateWay.SelectedItem

            $Gatewaytemporal = Get-AzVirtualNetworkGateway -Name $GateWayforVPN -ResourceGroupName $ResourceName
            Set-AzVirtualNetworkGateway -VirtualNetworkGateway $Gatewaytemporal -VpnClientAddressPool ($WPFtextBox_AddressPool.Text).Trim() -ErrorAction SilentlyContinue

            Add-AzVpnClientRootCertificate -VpnClientRootCertificateName $P2SRootCertName -VirtualNetworkGatewayname $GateWayforVPN -ResourceGroupName $ResourceName -PublicCertData $azureCert
            $WPFbuttom_CreateCertAzure.IsEnabled = $false
            $WPFbuttom_DeleteCertAzure.IsEnabled = $true
            $VPNApptext = " Do you want to download the VPN Client? "
            $VPNAppconf = [Microsoft.VisualBasic.Interaction]::MsgBox($VPNApptext,'OKCancel,Question',"Do you want to download the VPN Client")
            Switch($VPNAppconf){
                'OK'{

                     Write-Host "We're creating the VPN Client, It can takes several minutes, please wait" -ForegroundColor Yellow
                     $profile=New-AzVpnClientConfiguration -ResourceGroupName $ResourceName -Name $Gateway -AuthenticationMethod "EapTls"
                     $clnt = new-object System.Net.WebClient
                     $url = $profile.VPNProfileSASUrl
                     New-Item -Path ($Path + "\VPNClient") -ItemType directory
                     $file = $Path + "\VPNClient\DataOnly.zip"
                     $clnt.DownloadFile($url,$file)
                     Rename-Item -Path $file -NewName "VPNClientInstallApp.zip"
                     Write-Host "We've downloaded the VPN Client to this location: ($path\VPNClient\VPNClientInstallApp.zip)" -ForegroundColor Yellow

                     explorer ($Path + "\VPNClient")
                   }
                }

        }Else{
            Write-Host "You are using a Radius Server with the GateWay $Gateway, therefore you don't need a certificate for this configuration, select other GateWay or switch the configuration to 'Azure Certificate' within the Gateway configuration in Azure." -ForegroundColor Yellow -BackgroundColor Red
            [void] [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")
            $textradius = " You are using a Radius Server with the GateWay: $Gateway, therefore you don't need a certificate for this configuration, select other GateWay or switch the configuration to 'Azure Certificate' within the Gateway configuration in Azure."
            $yesradius = [Microsoft.VisualBasic.Interaction]::MsgBox($textradius,'OKOnly,Exclamation',"Radius Server configured")

        }

    }Else{
        Write-Warning "All Azure parameters are required"
        $testNo64bit = " All Azure parameters are required "
        $NoAzure = [Microsoft.VisualBasic.Interaction]::MsgBox($testNo64bit,'OkOnly,Critical,SystemModal,Exclamation',"Create Cert Requirement")
        }
    $FormMain.Cursor = "Arrow"

})

$WPFbutton_AP.Add_Click({
  $APIpRange = ($WPFtextBox_AddressPool.Text).Trim()
  $validRange = validIpRange($APIpRange)
  If($validRange){
    Try{
        $FormMain.Cursor = "Wait"
        Write-Host "We're writing the VPN Client Address Pool Ip Range, please wait" -ForegroundColor Yellow
        $GatewayAP = Get-AzVirtualNetworkGateway -Name $Gateway -ResourceGroupName $ResourceName
        Set-AzVirtualNetworkGateway -VirtualNetworkGateway $GatewayAP -VpnClientAddressPool ($WPFtextBox_AddressPool.Text).Trim() -ErrorAction SilentlyContinue
        Write-Host "We've witten the IP Range " $WPFtextBox_AddressPool.Text " to your VPN Client Address Pool" -ForegroundColor Yellow
        $FormMain.Cursor = "Arrow"
    }
    Catch [System.Exception]{
        $err = ($error[0].Exception | out-string)

        Write-Host $err -ForegroundColor Red -BackgroundColor Yellow
    }Finally{
        Write-Host "Please solve the error to continue" -ForegroundColor Yellow
    }
  }Else{
    Write-Host "Please enter a valid IP Range!" -ForegroundColor Red
  }

})

$WPFbuttom_DeleteCertOnpremise.Add_Click({
    Write-Warning "You are trying to remove the local certifiates"
    $removecerttext = " Do you really want to remove the created certificates? "
    $removecertconf = [Microsoft.VisualBasic.Interaction]::MsgBox($removecerttext,'OKCancel,Question',"Delete Certificates")
    switch ($removecertconf) {
       'OK'{
            DeleteCerts -rootcert $certFilepfx -clitncert $certFile -removefromcerdir $true -txtfile $txtfile
            $WPFbuttom_DeleteCertOnpremise.IsEnabled = $false
            $WPFbuttom_CreateCertOnpremise.IsEnabled = $true
            $WPFbuttom_CreateCertAzure.IsEnabled = $false
        }
    }

})

$WPFbuttom_DeleteCertAzure.Add_Click({
    $FormMain.Cursor = "Wait"
    $removecertazuretext = " Do you really want to remove the Certificate on Azure? "
    $removecertazureconf = [Microsoft.VisualBasic.Interaction]::MsgBox($removecertazuretext,'OKCancel,Question',"Delete Certificates")
    switch ($removecertazureconf) {
       'OK'{
            Write-Host "We've removing the certificate on Azure, It can takes several minutes, please wait" -ForegroundColor Yellow
            $GateWayforVPN = $WPFcomboBox_SelectGateWay.SelectedItem
            Remove-AzVpnClientRootCertificate -VpnClientRootCertificateName $P2SRootCertName -VirtualNetworkGatewayname $GateWayforVPN -ResourceGroupName $ResourceName -PublicCertData $azureCert
            $WPFbuttom_CreateCertAzure.IsEnabled = $true
            $WPFbuttom_DeleteCertAzure.IsEnabled = $false

            }

    }
    $FormMain.Cursor = "Arrow"
})

$WPFbuttom_Exit.Add_Click({$FormMain.Close()})

$FormMain.ResizeMode = "NoResize"

$FormMain.ShowDialog() | out-null



