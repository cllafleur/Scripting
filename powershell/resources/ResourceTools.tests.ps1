$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-module -force $here\RecruitingResourcesTools.psm1

Describe 'Remove-CommentSection' {
    It 'Removes Xml comment from content parameter' {
        $content = '<?xml version="1.0" encoding="utf-8"?>
        <root>
          <!-- 
            Microsoft ResX Schema 
            
            Version 2.0
            
            The primary goals of this format is to allow a simple XML format 
            that is mostly human readable. The generation and parsing of the 
            various data types are done through the TypeConverter classes 
            associated with the data types.
            
            Example:
            
            ... ado.net/XML headers & schema ...
            <resheader name="resmimetype">text/microsoft-resx</resheader>
            <resheader name="version">2.0</resheader>
            <resheader name="reader">System.Resources.ResXResourceReader, System.Windows.Forms, ...</resheader>
            <resheader name="writer">System.Resources.ResXResourceWriter, System.Windows.Forms, ...</resheader>
            <data name="Name1"><value>this is my long string</value><comment>this is a comment</comment></data>
            <data name="Color1" type="System.Drawing.Color, System.Drawing">Blue</data>
            <data name="Bitmap1" mimetype="application/x-microsoft.net.object.binary.base64">
                <value>[base64 mime encoded serialized .NET Framework object]</value>
            </data>
            <data name="Icon1" type="System.Drawing.Icon, System.Drawing" mimetype="application/x-microsoft.net.object.bytearray.base64">
                <value>[base64 mime encoded string representing a byte array form of the .NET Framework object]</value>
                <comment>This is a comment</comment>
            </data>
          -->
          <resheader name="resmimetype">
          <value>text/microsoft-resx</value>
          </resheader>
          <resheader name="version">
          <value>2.0</value>
          </resheader>
        </root>'
        $expected = '<?xml version="1.0" encoding="utf-8"?>
        <root>
          <resheader name="resmimetype">
          <value>text/microsoft-resx</value>
          </resheader>
          <resheader name="version">
          <value>2.0</value>
          </resheader>
        </root>'

        $result = Remove-XmlCommentSection $content
        $result | Should be $expected
    }
    It 'Removes Xml comment from content pipeline' {
        $content = '<?xml version="1.0" encoding="utf-8"?>
        <root>
          <!-- 
            Microsoft ResX Schema 
            
            Version 2.0
            
            The primary goals of this format is to allow a simple XML format 
            that is mostly human readable. The generation and parsing of the 
            various data types are done through the TypeConverter classes 
            associated with the data types.
            
            Example:
            
            ... ado.net/XML headers & schema ...
            <resheader name="resmimetype">text/microsoft-resx</resheader>
            <resheader name="version">2.0</resheader>
            <resheader name="reader">System.Resources.ResXResourceReader, System.Windows.Forms, ...</resheader>
            <resheader name="writer">System.Resources.ResXResourceWriter, System.Windows.Forms, ...</resheader>
            <data name="Name1"><value>this is my long string</value><comment>this is a comment</comment></data>
            <data name="Color1" type="System.Drawing.Color, System.Drawing">Blue</data>
            <data name="Bitmap1" mimetype="application/x-microsoft.net.object.binary.base64">
                <value>[base64 mime encoded serialized .NET Framework object]</value>
            </data>
            <data name="Icon1" type="System.Drawing.Icon, System.Drawing" mimetype="application/x-microsoft.net.object.bytearray.base64">
                <value>[base64 mime encoded string representing a byte array form of the .NET Framework object]</value>
                <comment>This is a comment</comment>
            </data>
          -->
          <resheader name="resmimetype">
          <value>text/microsoft-resx</value>
          </resheader>
          <resheader name="version">
          <value>2.0</value>
          </resheader>
        </root>'
        $expected = '<?xml version="1.0" encoding="utf-8"?>
        <root>
          <resheader name="resmimetype">
          <value>text/microsoft-resx</value>
          </resheader>
          <resheader name="version">
          <value>2.0</value>
          </resheader>
        </root>'

        $result = $content | Remove-XmlCommentSection
        $result | Should be $expected
    }
}

Describe "Get-ResourceKeysFrom" {
    Context "file contains only data xml attributes" {
        $contentFile = '  <data name="A_valid_email_should_be_provided_for_user_creation" xml:space="preserve">
    <value>A valid email should be provided to create an account. "{0}" was provided.</value>
  </data>
  <data name="AccessDenied" xml:space="preserve">
    <value>You do not have permission to view this directory or page.</value>
  </data>
  <data name="AccessDeniedTitle" xml:space="preserve">
    <value>Forbidden: Access is denied.</value>
  </data>
  <data name="AccountCreationRequestsByStatus" xml:space="preserve">
    <value>Pending account creation requests</value>
  </data>
  <data name="AdditionalInformationTitle1" xml:space="preserve">
    <value>Additional information</value>
  </data>
'
        function global:Mock-Get-Content { return $contentFile }
        Set-Alias Get-Content Mock-Get-Content -scope Global

        It "returns the list of resource keys from the specified filename" {


            $expected = @(
                "A_valid_email_should_be_provided_for_user_creation",
                "AccessDenied",
                "AccessDeniedTitle",
                "AccountCreationRequestsByStatus",
                "AdditionalInformationTitle1"
            )
            #Mock Get-Content { return $contentFile }
            Mock Remove-XmlCommentSection { return $content }

            $result = Get-ResourceKeysFrom "g:\\fakeFile.resx"
            $result | Should be $expected
        }

        Remove-Item Alias:\Get-Content
        Remove-Item Function:\Mock-Get-Content
    }
    Context "file not contains only data xml elements" {
        $contentFile = '  <data name="A_valid_email_should_be_provided_for_user_creation" xml:space="preserve">
        <value>A valid email should be provided to create an account. "{0}" was provided.</value>
      </data>
      <data name="AccessDenied" xml:space="preserve">
        <value>You do not have permission to view this directory or page.</value>
      </data>
      <data name="AccessDeniedTitle" xml:space="preserve">
        <value>Forbidden: Access is denied.</value>
      </data>
      <data name="AccountCreationRequestsByStatus" xml:space="preserve">
        <value>Pending account creation requests</value>
      </data>
      <resheader name="version">
      <value>2.0</value>
    </resheader>
    <resheader name="reader">
      <value>System.Resources.ResXResourceReader, System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089</value>
    </resheader>
    <resheader name="writer">
      <value>System.Resources.ResXResourceWriter, System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089</value>
    </resheader>
      <data name="AdditionalInformationTitle1" xml:space="preserve">
        <value>Additional information</value>
      </data>
    '
        function global:Mock-Get-Content { return $contentFile }
        Set-Alias Get-Content Mock-Get-Content -scope Global
    
        It "returns the list of resource keys from the specified filename ignoring keys in reaheader" {
            $expected = @(
                "A_valid_email_should_be_provided_for_user_creation",
                "AccessDenied",
                "AccessDeniedTitle",
                "AccountCreationRequestsByStatus",
                "AdditionalInformationTitle1"
            )
            #Mock Get-Content { return $contentFile }
            Mock Remove-XmlCommentSection { return $content }
    
            $result = Get-ResourceKeysFrom "g:\\fakeFile.resx"
            $result | Should be $expected
        }
    
        Remove-Item Alias:\Get-Content
        Remove-Item Function:\Mock-Get-Content 
    }
}

Describe "Get-ResourcesFrom" {
    Context "context file contains only data xml attributes" {
        $contentFile = '  <data name="A_valid_email_should_be_provided_for_user_creation" xml:space="preserve">
        <value>A valid email should be provided to create an account. "{0}" was provided.</value>
      </data>
      <data name="AccessDenied" xml:space="preserve">
        <value>You do not have permission to view this directory or page.</value>
      </data>
    '
        function global:Mock-Get-Content { return $contentFile }
        Set-Alias Get-Content Mock-Get-Content -scope Global
    
        It "returns a hash table with all the resource keys" {
            $expected = @{
                "A_valid_email_should_be_provided_for_user_creation" =
                '  <data name="A_valid_email_should_be_provided_for_user_creation" xml:space="preserve">
        <value>A valid email should be provided to create an account. "{0}" was provided.</value>
      </data>';
                "AccessDenied"                                       = '
      <data name="AccessDenied" xml:space="preserve">
        <value>You do not have permission to view this directory or page.</value>
      </data>'
            }
            #Mock Get-Content { return $contentFile }
            Mock Remove-XmlCommentSection { return $content }
    
            $result = Get-ResourcesFrom "g:\\fakeFile.resx"
            $result["A_valid_email_should_be_provided_for_user_creation"] | Should be $expected["A_valid_email_should_be_provided_for_user_creation"]
            $result["AccessDenied"] | Should be $expected["AccessDenied"]
        }
    
        Remove-Item Alias:\Get-Content
        Remove-Item Function:\Mock-Get-Content 
    }
}

Describe "Get-ResourceCommentsFrom" {
    Context "File contains one resource with one comment" {
        $contentFile = '<data name="A_valid_email_should_be_provided_for_user_creation" xml:space="preserve">
        <value>A valid email should be provided to create an account. "{0}" was provided.</value>
        <comment>The comment</comment>
      </data> '
        function global:Mock-Get-Content { return $contentFile }
        Set-Alias Get-Content Mock-Get-Content -scope Global

        It "returns the comment with the key" {
            $expected = @{
                "A_valid_email_should_be_provided_for_user_creation" =
                '
        <comment>The comment</comment>'
            }
            #Mock Get-Content { return $contentFile }
            Mock Remove-XmlCommentSection { return $content }
    
            $result = Get-ResourceCommentsFrom "g:\\fakeFile.resx"
            $result["A_valid_email_should_be_provided_for_user_creation"] | Should be $expected["A_valid_email_should_be_provided_for_user_creation"]
        }
    
        Remove-Item Alias:\Get-Content
        Remove-Item Function:\Mock-Get-Content 
    }

    Context "File contains one resource with a comment and another resource without comment" {
        $contentFile = '<data name="A_valid_email_should_be_provided_for_user_creation" xml:space="preserve">
        <value>A valid email should be provided to create an account. "{0}" was provided.</value>
        <comment>The comment</comment>
      </data>
      <data name="AccessDenied" xml:space="preserve">
        <value>You do not have permission to view this directory or page.</value>
      </data>
    '
        function global:Mock-Get-Content { return $contentFile }
        Set-Alias Get-Content Mock-Get-Content -scope Global

        It "returns the comment with the key" {
            $expected = @{
                "A_valid_email_should_be_provided_for_user_creation" =
                '
        <comment>The comment</comment>'
            }
            #Mock Get-Content { return $contentFile }
            Mock Remove-XmlCommentSection { return $content }
    
            $result = Get-ResourceCommentsFrom "g:\\fakeFile.resx"
            $result["A_valid_email_should_be_provided_for_user_creation"] | Should be $expected["A_valid_email_should_be_provided_for_user_creation"]
        }
    
        Remove-Item Alias:\Get-Content
        Remove-Item Function:\Mock-Get-Content 
    }
}

Describe "Get-ResourcesToInsert" {
    Context "Translated language contains all resource keys to insert" {
        $translatedLanguage = @{
            "A_valid_email_should_be_provided_for_user_creation" =
            '<data name="A_valid_email_should_be_provided_for_user_creation" xml:space="preserve"><value>A valid email should be provided to create an account. "{0}" was provided.</value></data>';
            "AccessDenied"                                       =
            '<data name="AccessDenied" xml:space="preserve"><value>You do not have permission to view this directory or page.</value></data>';
            "AdditionalInformationTitle1"                        =
            '<data name="AdditionalInformationTitle1" xml:space="preserve"><value>Additional information</value></data>'
        }
        It "returns one resource" {
            $listofWantedKeys = @("AccessDenied")
            $expected = '<data name="AccessDenied" xml:space="preserve"><value>You do not have permission to view this directory or page.</value></data>'

            $result = Get-ResourcesToInsert $listofWantedKeys $translatedLanguage @{} @{}
            $result | Should be $expected
        }
        It "returns three resources in specific order" {
            $listofWantedKeys = @("AccessDenied", "A_valid_email_should_be_provided_for_user_creation", "AdditionalInformationTitle1")
            $expected =
            '<data name="AccessDenied" xml:space="preserve"><value>You do not have permission to view this directory or page.</value></data>' +
            '<data name="A_valid_email_should_be_provided_for_user_creation" xml:space="preserve"><value>A valid email should be provided to create an account. "{0}" was provided.</value></data>' +
            '<data name="AdditionalInformationTitle1" xml:space="preserve"><value>Additional information</value></data>'

            $result = Get-ResourcesToInsert $listofWantedKeys $translatedLanguage @{} @{}
            $result | Should be $expected
        }
    }

    Context "Translated language contains missing some keys and use fallback language" {
        $translatedLanguage = @{
            "A_valid_email_should_be_provided_for_user_creation" =
            '<data name="A_valid_email_should_be_provided_for_user_creation" xml:space="preserve"><value>A valid email should be provided to create an account. "{0}" was provided.</value></data>'
        }
        $fallbackLanguage = @{
            "A_valid_email_should_be_provided_for_user_creation" =
            '<data name="A_valid_email_should_be_provided_for_user_creation" xml:space="preserve"><value>A valid email from fallback should be provided to create an account. "{0}" was provided.</value></data>';
            "AccessDenied"                                       =
            '<data name="AccessDenied" xml:space="preserve"><value>You do not have permission to view this directory or page.</value></data>';
            "AdditionalInformationTitle1"                        =
            '<data name="AdditionalInformationTitle1" xml:space="preserve"><value>Additional information</value></data>'
        }
        
        It "returns one resource from fallback language" {
            $listofWantedKeys = @("AccessDenied")
            $expected = '<data name="AccessDenied" xml:space="preserve"><value>You do not have permission to view this directory or page.</value></data>'

            $result = Get-ResourcesToInsert $listofWantedKeys $translatedLanguage $fallbackLanguage @{}
            $result | Should be $expected
        }
        It "returns three resources one from translated langauge and two from fallbackLanguage" {
            $listofWantedKeys = @("AccessDenied", "A_valid_email_should_be_provided_for_user_creation", "AdditionalInformationTitle1")
            $expected =
            '<data name="AccessDenied" xml:space="preserve"><value>You do not have permission to view this directory or page.</value></data>' +
            '<data name="A_valid_email_should_be_provided_for_user_creation" xml:space="preserve"><value>A valid email should be provided to create an account. "{0}" was provided.</value></data>' +
            '<data name="AdditionalInformationTitle1" xml:space="preserve"><value>Additional information</value></data>'

            $result = Get-ResourcesToInsert $listofWantedKeys $translatedLanguage $fallbackLanguage @{}
            $result | Should be $expected
        }
    }

    Context "Translated language contains all resource keys to insert and comment must be inserted" {
        $translatedLanguage = @{
            "A_valid_email_should_be_provided_for_user_creation" =
            '<data name="A_valid_email_should_be_provided_for_user_creation" xml:space="preserve"><value>A valid email should be provided to create an account. "{0}" was provided.</value></data>';
            "AccessDenied"                                       =
            '<data name="AccessDenied" xml:space="preserve"><value>You do not have permission to view this directory or page.</value></data>';
            "AdditionalInformationTitle1"                        =
            '<data name="AdditionalInformationTitle1" xml:space="preserve"><value>Additional information</value></data>'
        }
        $resourceComments = @{ "AccessDenied" = "<comment>Inserted comment</comment>" }
        It "returns one resource" {
            $listofWantedKeys = @("AccessDenied")
            $expected = '<data name="AccessDenied" xml:space="preserve"><value>You do not have permission to view this directory or page.</value><comment>Inserted comment</comment></data>'

            $result = Get-ResourcesToInsert $listofWantedKeys $translatedLanguage @{} $resourceComments
            $result | Should be $expected
        }
        It "returns three resources in specific order" {
            $listofWantedKeys = @("AccessDenied", "A_valid_email_should_be_provided_for_user_creation", "AdditionalInformationTitle1")
            $expected =
            '<data name="AccessDenied" xml:space="preserve"><value>You do not have permission to view this directory or page.</value><comment>Inserted comment</comment></data>' +
            '<data name="A_valid_email_should_be_provided_for_user_creation" xml:space="preserve"><value>A valid email should be provided to create an account. "{0}" was provided.</value></data>' +
            '<data name="AdditionalInformationTitle1" xml:space="preserve"><value>Additional information</value></data>'

            $result = Get-ResourcesToInsert $listofWantedKeys $translatedLanguage @{} $resourceComments
            $result | Should be $expected
        }
    }
}

Describe "Get-UpdatedNeutralLanguageFile" {
    Context "File with only data xml element" {
        $contentFile = '<root>  <data name="A_valid_email_should_be_provided_for_user_creation" xml:space="preserve">
        <value>A valid email should be provided to create an account. "{0}" was provided.</value>
      </data>
      <data name="AccessDenied" xml:space="preserve">
        <value>You do not have permission to view this directory or page.</value>
      </data></root>'
        function global:Mock-Get-Content { return $contentFile }
        Set-Alias Get-Content Mock-Get-Content -scope Global
    
        It "returns file with new content" {
            $newContent = "super `r`n content"
            $expected = "<root>" + $newContent + "`r`n</root>"

            $result = Get-UpdatedNeutralLanguageFile "g:\\dumbfile.resx" $newContent

            $result | Should be $expected
        }
        
        Remove-Item Alias:\Get-Content
        Remove-Item Function:\Mock-Get-Content
    }
    Context "File contains xml comments and data xml element" {
        $contentFile = '<root><!--
<data name="A_valid_email_should_be_provided_for_user_creation" xml:space="preserve">
<value>A valid email should be provided to create an account. "{0}" was provided.</value>
</data>
-->' +
        '  <data name="A_valid_email_should_be_provided_for_user_creation" xml:space="preserve">
        <value>A valid email should be provided to create an account. "{0}" was provided.</value>
      </data>
      <data name="AccessDenied" xml:space="preserve">
        <value>You do not have permission to view this directory or page.</value>
      </data></root>'
        function global:Mock-Get-Content { return $contentFile }
        Set-Alias Get-Content Mock-Get-Content -scope Global
    
        It "returns file with untouched comments and new content" {
            $newContent = "super `r`n content"
            $expected = '<root><!--
<data name="A_valid_email_should_be_provided_for_user_creation" xml:space="preserve">
<value>A valid email should be provided to create an account. "{0}" was provided.</value>
</data>
-->' + $newContent + "`r`n</root>"

            $result = Get-UpdatedNeutralLanguageFile "g:\\dumbfile.resx" $newContent

            $result | Should be $expected
        }
        
        Remove-Item Alias:\Get-Content
        Remove-Item Function:\Mock-Get-Content
    }
}

Describe "Get-ResourceDataWithCommentInserted" {
    It "inserts comment element into a data xml element" {
        $dataElement = '      <data name="AccessDenied" xml:space="preserve">
    <value>You do not have permission to view this directory or page.</value>
 </data>'
        $commentToInsert = '
   <comment>the comment</comment>'
        $expectedResult = '      <data name="AccessDenied" xml:space="preserve">
    <value>You do not have permission to view this directory or page.</value>
   <comment>the comment</comment>
 </data>'

        $result = Get-ResourceDataWithCommentInserted $dataElement $commentToInsert
        $result | Should Be $expectedResult
    }
}
