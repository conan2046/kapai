# Field and reference validation invoked by the existing Unity-owned export chain.
function Test-UnityDongFuTables($Tables, [string]$Root) {
    $schema = Get-Content (Join-Path $PSScriptRoot 'dongfu-schema.json') -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
    foreach ($definition in $schema.tables) {
        $rows = @($Tables[$definition.name])
        if (-not $rows.Count) { throw "DongFu table has no field example: $($definition.name)" }
        foreach ($row in $rows) {
            if ($row.id -lt 1 -or $row.enabled -notin @(0,1)) { throw "DongFu invalid id/enabled: $($definition.name)" }
            foreach ($field in $definition.fields) {
                if (-not $row.Contains($field.key)) { throw "DongFu missing field: $($definition.name).$($field.key)" }
                $value = $row[$field.key]
                if ($field.type -eq 'number' -and $value -lt 0) { throw "DongFu negative field: $($field.key)" }
                if ($field.type -eq 'json') {
                    if ($value -isnot [array]) { throw "DongFu expected array: $($field.key)" }
                    if ($field.key -in @('cost_items','outputs','attributes','combat_attributes')) {
                        $ids=@{}
                        foreach ($pair in $value) {
                            if ($pair -isnot [array] -or $pair.Count -ne 2 -or "$($pair[0])" -notmatch '^\d+$' -or "$($pair[1])" -notmatch '^\d+$' -or $pair[0] -lt 1 -or $pair[1] -lt 1 -or $ids.ContainsKey([string]$pair[0])) {
                                throw "DongFu invalid/duplicate resource or attribute pair: $($field.key)"
                            }
                            $ids[[string]$pair[0]]=$true
                        }
                    } else {
                        $seen=@{}
                        foreach ($id in $value) {
                            if ("$id" -notmatch '^\d+$' -or $id -lt 1 -or $seen.ContainsKey([string]$id)) { throw "DongFu invalid/duplicate member: $($field.key)" }
                            $seen[[string]$id]=$true
                        }
                    }
                }
            }
        }
    }
    $enumFields=@{
        dongfu_building=@{function_type=@('garden','spirit','alchemy','forge','library')}
        dongfu_recipe=@{kind=@('alchemy','forge')}
        dongfu_effect=@{effect_kind=@('permanent_attribute','experience');target_scope=@('lineup','player_experience')}
        dongfu_spirit_level=@{target_scope=@('lineup')}
        dongfu_book_reward=@{condition_kind=@('book','count','combination','complete');target_scope=@('lineup')}
        dongfu_settings=@{activation_mode=@('manual');task_bonus_mode=@('snapshot')}
    }
    foreach ($table in $enumFields.Keys) { foreach ($row in $Tables[$table]) { foreach ($key in $enumFields[$table].Keys) {
        if ($row[$key] -notin $enumFields[$table][$key]) { throw "DongFu unknown enum: ${table}.${key}" }
    } } }
    foreach ($row in $Tables.dongfu_spirit_level) {
        if ($row.growth_reduction_bp -ge 10000) { throw 'DongFu growth reduction must be below 10000.' }
    }
    foreach ($row in $Tables.dongfu_recipe) {
        if ($row.duration_seconds -lt 1 -or $row.batch_limit -lt 1 -or $row.batch_cost_bp -lt 1 -or $row.batch_cost_bp -gt 10000 -or $row.output_count -lt 1) { throw 'DongFu invalid recipe time/batch/count.' }
    }
    foreach ($row in $Tables.dongfu_settings) {
        if ($row.id -ne 1 -or $row.schema_version -ne 1 -or $row.offline_efficiency_bp -gt 10000 -or $row.auto_plant -ne 0) { throw 'DongFu settings use unsupported version/automatic planting.' }
    }
    $active=@{}
    foreach ($definition in $schema.tables) {
        $active[$definition.name]=@{}
        foreach ($row in $Tables[$definition.name]) { if ($row.enabled -eq 1) { $active[$definition.name][[string]$row.id]=$row } }
    }
    # Disabled examples define fields only. Active records must reference real enabled definitions.
    function Require-DongFuRef([string]$Table,[long]$Id) {
        if (-not $active[$Table].ContainsKey([string]$Id)) { throw "DongFu inactive/missing reference: ${Table}/${Id}" }
    }
    $itemIds=@{}
    foreach ($row in @(Get-Content (Join-Path $Root 'unityserver/config/json/item.json') -Raw -Encoding UTF8 | ConvertFrom-Json)) { $itemIds[[string]$row.id]=$true }
    function Require-DongFuItem([long]$Id) { if (-not $itemIds.ContainsKey([string]$Id)) { throw "DongFu missing formal item: $Id" } }
    foreach ($definition in $schema.tables) { foreach ($row in $active[$definition.name].Values) {
        foreach ($field in @('cost_items','outputs')) { if ($row.Contains($field)) { foreach ($pair in $row[$field]) { Require-DongFuItem $pair[0] } } }
    } }
    foreach ($row in $active.dongfu_crop.Values) { Require-DongFuItem $row.seed_item_id; Require-DongFuRef 'dongfu_building' $row.building_id; if ($row.grow_seconds -lt 1 -or -not $row.outputs.Count) { throw 'DongFu active crop has no time/output.' } }
    foreach ($crop in $active.dongfu_crop.Values) {
        if ($crop.middle_progress_bp -lt 1 -or $crop.middle_progress_bp -ge 10000 -or $crop.water_after_seconds -lt 0 -or $crop.bug_after_seconds -lt 0 -or $crop.abnormal_extension_bp -lt 0 -or $crop.abnormal_extension_bp -gt 100000 -or $crop.seed_price_gold -lt 0) { throw 'Garden growth/maintenance fields are invalid.' }
        foreach ($field in @('icon_key','initial_resource_key','middle_resource_key','mature_resource_key')) {
            $key=[string]$crop[$field]
            if ([string]::IsNullOrWhiteSpace($key) -or $key.Contains('..') -or -not (Test-Path -LiteralPath (Join-Path $Root ('unityclient/Assets/'+$key+'.png')))) { throw "Garden stage sprite missing: $field/$key" }
        }
    }
    $gardenPlots=@($active.dongfu_garden_plot.Values)
    if ($gardenPlots.Count -and $gardenPlots.Count -ne 36) { throw 'Garden requires exactly 36 enabled plot definitions.' }
    foreach ($plot in $gardenPlots) {
        if ($plot.id -lt 1 -or $plot.id -gt 36 -or $plot.unlock_realm_id -lt 1 -or $plot.unlock_realm_id -gt 550) { throw 'Garden plot/realm ID invalid.' }
    }
    foreach ($row in $active.dongfu_recipe.Values) {
        Require-DongFuRef 'dongfu_building' $row.building_id; Require-DongFuItem $row.learn_item_id
        if (-not $row.cost_items.Count) { throw 'DongFu active recipe has no costs.' }
        if ($row.kind -eq 'alchemy') { Require-DongFuItem $row.output_item_id; if ($row.equip_template_id -ne 0) { throw 'DongFu pill recipe has equipment output.' } }
        elseif ($row.equip_template_id -lt 1 -or $row.output_item_id -ne 0) { throw 'DongFu forge recipe must output an equipment template.' }
    }
    foreach ($row in $active.dongfu_effect.Values) {
        Require-DongFuItem $row.item_id
        if ($row.effect_kind -eq 'permanent_attribute' -and ($row.target_scope -ne 'lineup' -or -not $row.attributes.Count -or $row.experience -ne 0)) { throw 'DongFu permanent effects target lineup attributes.' }
        if ($row.effect_kind -eq 'experience' -and ($row.target_scope -ne 'player_experience' -or $row.attributes.Count -or $row.experience -lt 1)) { throw 'DongFu experience effect is not a permanent combat attribute.' }
    }
    foreach ($set in $active.dongfu_book_set.Values) {
        if (-not $set.book_ids.Count) { throw 'DongFu enabled book set is empty.' }
        foreach ($id in $set.book_ids) { Require-DongFuRef 'dongfu_book' $id; if ($active.dongfu_book[[string]$id].set_id -ne $set.id) { throw 'DongFu book/set membership mismatch.' } }
    }
    foreach ($book in $active.dongfu_book.Values) {
        Require-DongFuItem $book.item_id; Require-DongFuRef 'dongfu_book_set' $book.set_id
        if ($book.id -notin $active.dongfu_book_set[[string]$book.set_id].book_ids) { throw 'DongFu book is absent from its set.' }
    }
    foreach ($reward in $active.dongfu_book_reward.Values) {
        Require-DongFuRef 'dongfu_book_set' $reward.set_id
        $members=$active.dongfu_book_set[[string]$reward.set_id].book_ids
        if (-not $reward.attributes.Count) { throw 'DongFu enabled collection reward has no attributes.' }
        foreach ($id in $reward.required_book_ids) { if ($id -notin $members) { throw 'DongFu reward references another set.' } }
        switch ($reward.condition_kind) {
            'book' { if ($reward.required_book_ids.Count -ne 1 -or $reward.required_count -ne 0) { throw 'DongFu single-book condition invalid.' } }
            'count' { if ($reward.required_count -lt 1 -or $reward.required_count -gt $members.Count -or $reward.required_book_ids.Count) { throw 'DongFu count condition invalid.' } }
            'combination' { if ($reward.required_book_ids.Count -lt 2 -or $reward.required_count -ne 0) { throw 'DongFu combination condition invalid.' } }
            'complete' { if ($reward.required_count -ne 0 -or $reward.required_book_ids.Count) { throw 'DongFu complete condition must use actual set members.' } }
        }
    }
}
