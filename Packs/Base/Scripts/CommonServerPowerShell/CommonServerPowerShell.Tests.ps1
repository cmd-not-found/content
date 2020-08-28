BeforeAll {
    . $PSScriptRoot\CommonServerPowerShell.ps1
}


Describe 'Check-DemistoServerRequest' {
    It 'Check that a call to demisto DemistoServerRequest mock works. Should always return an empty response' {
        global:DemistoServerRequest @{} | Should -BeNullOrEmpty
        $demisto.GetAllSupportedCommands() | Should -BeNullOrEmpty
    }
}

Describe 'Check-UtilityFunctions' {
    It "ArgToList" {
        $r = argToList "a,b,c,2"
        $r.GetType().IsArray | Should -BeTrue
        $r[0] | Should -Be "a"
        $r.Length | Should -Be 4
        $r = argToList '["a","b","c",2]'
        $r.GetType().IsArray | Should -BeTrue
        $r[0] | Should -Be "a"
        $r[3] | Should -Be 2
        $r.Length | Should -Be 4
        $r = argToList @("a","b","c",2)
        $r.GetType().IsArray | Should -BeTrue
        $r[0] | Should -Be "a"
        $r[3] | Should -Be 2
        $r.Length | Should -Be 4
        $r = argToList "a"
        $r.GetType().IsArray | Should -BeTrue
        $r[0] | Should -Be "a"
        $r.Length | Should -Be 1
    }

    It "ReturnOutputs" {
        $msg = "Human readable"
        $r = ReturnOutputs $msg @{Test="test"} @{Raw="raw"}
        $r.ContentsFormat | Should -Be "json"
        $r.HumanReadable | Should -Be $msg
        $r.EntryContext.Test | Should -Be "test"
        $r.Contents.Raw | Should -Be "raw"
        $r = ReturnOutputs $msg
        $r.ContentsFormat | Should -Be "text"
        $r.Contents | Should -Be $msg
    }

    It "ReturnOutputs PsCustomObject" {
        $msg = "Human readable"
        $output = [PsCustomObject]@{Test="test"}
        $raw = [PSCustomObject]@{Raw="raw"}
        $r = ReturnOutputs $msg  $output $raw
        $r.ContentsFormat | Should -Be "json"
        $r.HumanReadable | Should -Be $msg
        $r.EntryContext.Test | Should -Be "test"
        $r.Contents.Raw | Should -Be "raw"
        $r = ReturnOutputs $msg
        $r.ContentsFormat | Should -Be "text"
        $r.Contents | Should -Be $msg
    }

    It "ReturnError simple" {
        $msg = "this is an error"
        $r = ReturnError $msg
        $r.ContentsFormat | Should -Be "text"
        $r.Type | Should -Be 4
        $r.Contents | Should -Be $msg
        $r.EntryContext | Should -BeNullOrEmpty
    }
    Context "Check log function" {
        BeforeAll {
            Mock DemistoServerLog {}
        }

        It "ReturnError complex" {
            # simulate an error
            Test-JSON "{badjson}" -ErrorAction SilentlyContinue -ErrorVariable err
            $msg = "this is a complex error"
            $r = ReturnError $msg $err @{Failed = $true}
            $r.Contents | Should -Be $msg
            $r.EntryContext.Failed | Should -BeTrue
            # ReturnError call demisto.Error() make sure it was called
            Assert-MockCalled -CommandName DemistoServerLog -Times 2 -ParameterFilter {$level -eq "error"}
            Assert-MockCalled -CommandName DemistoServerLog -Times 1 -ParameterFilter {$msg.Contains("Cannot parse the JSON")}
        }
    }
    Context "TableToMarkdown" {
        BeforeAll {
            $HashTableWithTwoEntries = @(
            @{
                Index = '0'
                Name = 'First element'
            },
            @{
                Index = '1'
                Name = 'Second element'
            }
            )
            $HashTableWithOneEntry = @(
            @{
                Index = '0'
                Name = 'First element'
            })
            $OneElementObject = @()
            ForEach ($object in $HashTableWithOneEntry)
            {
                $OneElementObject += New-Object PSObject -Property $object
            }
            $TwoElementObject = @()
            ForEach ($object in $HashTableWithTwoEntries)
            {
                $TwoElementObject += New-Object PSObject -Property $object
            }
        }
        It "Empty list without a name" {
            TableToMarkdown @() | Should -Be "**No entries.**`n"
        }
        It "A list with one element and no name" {
            TableToMarkdown $OneElementObject | Should -Be "Name | Index`n--- | ---`nFirst element | 0`n"
        }
        It "A list with two elements and no name" {
            TableToMarkdown $TwoElementObject | Should -Be "Name | Index`n--- | ---`nFirst element | 0`nSecond element | 1`n"
        }
        It "Empty list with a name" {
            TableToMarkdown @() "Test Name" | Should -Be "### Test Name`n**No entries.**`n"
        }
        It "A list with two elements and a name" {
            TableToMarkdown $TwoElementObject "Test Name" | Should -Be "### Test Name`nName | Index`n--- | ---`nFirst element | 0`nSecond element | 1`n"
        }
        It "A list with one elements and a name" {
            TableToMarkdown $OneElementObject "Test Name" | Should -Be "### Test Name`nName | Index`n--- | ---`nFirst element | 0`n"
        }
        It "Check alias to ConvertTo-Markdown" {
            ConvertTo-Markdown @() "Test Name" | Should -Be "### Test Name`n**No entries.**`n"
        }
    }
}
