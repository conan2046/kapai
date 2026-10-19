# Shared by the formal exporter. Validates every row before any output is written.
function Test-UnityCombatTables($Tables, [string]$Root) {
    $effectFields=@('one','gear_value','turn','source_alive','source_summoned','source_hp','source_hp_bp','source_max_hp','source_attack','rage','target_hp','target_max_hp','target_missing_hp','target_hp_bp','target_alive','target_boss','target_shield','target_debuff_categories','target_has_debuff','source_hard_control','position')
    $effectFields+=@('source_position','target_hard_control','target_hp_bp_ceil','target_shield_amount','enemies_alive','target_attack_type')
    $contextFields=@{
        after_passive_targets=@('passive_trigger','passive_effect')
        passive_attempt_failed=@('effect_kind','passive_effect')
        before_debuff_resistance=@('hard_control')
        before_attribute_growth=@('passive_effect','parameter_value_1','parameter_value_2','parameter_value_3','parameter_value_4')
        before_passive_heal=@('amount')
        before_attribute_transfer=@('amount','passive_effect','attribute_type')
        before_periodic_proc=@('amount','periodic_input','live_owned_buff_targets')
        after_periodic_proc=@('amount','periodic_input')
        before_effect_attempt=@('effect_kind','passive_effect','target_present','base_duration')
        before_passive_value=@('amount','attribute_type','passive_effect','passive_trigger','target_present')
        before_thorns_damage=@('amount','passive_thorns')
        after_dispel_batch=@('removed_count')
        after_cleanse_batch=@('removed_count','removed_negative_count')
        before_skill_growth=@('passive_effect')
        before_passive_list=@('passive_trigger','effect_count','target_present','highest_enemy_combo_bp','highest_enemy_critical_bp','highest_enemy_debuff_bp','highest_enemy_counter_bp')
        before_stat=@('stat_kind')
        before_buff_attempt=@('parameter_count')
        buff_attempt_failed=@('immune')
        buff_attempt_applied=@('event_buff_owned','event_duration','event_stack_group','event_stack_count')
        before_passive_raw_parameters=@('passive_effect','parameter_path','parameter_count')
        after_passive_sequence=@('passive_trigger')
        after_heal=@('overheal','effective_heal','hp_before_bp','healing_total','recipient_count')
        after_revive=@('overheal','effective_heal','hp_before_bp')
        after_periodic_heal=@('overheal','effective_heal','hp_before_bp')
        shield_lost=@('shield_absorbed','shield_remaining','shield_parameter_count','shield_loss_basis','event_hp_loss','event_bonus','secondary_damage','expired','broken','dispelled','attacker_position')
        before_shield=@('parameter_count')
        after_primary_hit=@('amount','event_target_alive','had_shield')
        before_passive_parameters=@('passive_effect','passive_trigger','passive_count','parameter_count','target_present','target_summoned','same_team')
        after_passive_attribute_roll=@('passive_effect','passive_trigger','passive_count','parameter_count','target_present','target_summoned','same_team')
        before_kill_action=@('source_just_revived')
        accepted_kill_action=@('action_kind')
        kill_confirmed=@('kill_count')
        before_dot=@('amount','periodic_damage'); after_hit=@('amount'); before_buff=@('parameter_count')
        before_direct_damage=@('hit_index')
        after_attack=@('regular_skill','hit_index','amount','absorbed','counter_attack')
        before_attack=@('first_attack','counter_attack','hit_index')
        before_heal=@('periodic_heal')
        battle_begin=@('source_is_group_hp_leader')
        kill=@('victim_summoned','enemy_kill')
        after_combo=@('segments')
        after_skill_heal=@('processed_targets')
        after_thorns=@('amount','absorbed','passive_thorns')
        after_direct_kill=@('overkill')
        after_owned_shield_loss=@('shield_absorbed','broken')
        after_received_shield_loss=@('shield_absorbed','broken')
        after_self_shield=@('shield_amount','event_duration')
        after_guard_damage=@('attacker_alive')
        after_counter_damage=@('amount')
        after_periodic_damage=@('amount')
        death_observed=@('victim_summoned','effect_battle_count')
        after_buff_removed=@('buff_param0','remaining_turns')
        accepted_control=@('hard_control')
        after_direct_hp_loss=@('amount','received_damage_bp')
        after_critical_roll=@('critical','effect_battle_count')
        landed_attack=@('first_attack','counter_attack','hit_index')
        before_shield_passive=@('expired','broken')
        finalize_heal=@('amount');before_passive_revive=@('amount')
        before_skill_usefulness=@('source_team_second_hp_bp','source_team_mean_missing_hp_bp')
        strategy=@('one','allies_dead','allies_low','enemy_dots','tactic_revives','regular_revives','tactic_heals','regular_heals','tactic_targets','regular_targets','lowest_ally_hp_bp','lowest_ally_protected','source_hp_bp','enemies_untaunted','highest_enemy_controlled','highest_enemy_resistance_down','highest_enemy_boss','lowest_enemy_hp_bp','enemy_exposed')
    }
    $events=@('after_heal','after_revive','shield_lost','before_dot','before_buff','after_hit','before_heal','after_periodic_heal','action_start','after_cleanse','after_share','before_direct_damage','before_speed','death','after_regular','before_shield_damage','before_action_order')
    $ops=@('heal','restore_hp','damage','shield','buff','rage','cooldown','scale_amount','set_duration','scale_parameters','add_amount_bonus','add_parameter_bonus','set_parameter','multiply_amount')
    $targets=@('target','self','allies','enemies','lowest_ally','highest_gear_ally')
    $heroIds=@{}; $skillIds=@{}; $buffIds=@{}; $buffNames=@{}
    foreach($r in $Tables.hero_skill_role) { $heroIds[[string]$r.hero_id]=$true }
    $skills=[xml](Get-Content -LiteralPath (Join-Path $Root 'unityserver/config/xml/skill_basic.xml') -Raw -Encoding UTF8)
    foreach($r in $skills.DocumentElement.ChildNodes) { if($r.id){$skillIds[[string]$r.id]=$true} }
    # Original equipment actions carry protocol-only origins absent from skill_basic.
    # Derive their namespace from formal bindings; never admit these as cast skills.
    $gearOrigins=@{}
    foreach($binding in $Tables.combat_artifact){$gearOrigins["$($binding.effect_group):$(10000+[int]$binding.family)"]=$true}
    foreach($binding in $Tables.combat_set){
        $gearOrigins["$($binding.effect_group):$(10000+[int]$binding.suit_id)"]=$true
        $gearOrigins["$($binding.effect_group):$(11000+[int]$binding.suit_id)"]=$true
    }
    $additiveIds=@{};$additive=[xml](Get-Content -LiteralPath (Join-Path $Root 'unityserver/config/xml/skill_additive_effect.xml') -Raw -Encoding UTF8)
    foreach($r in $additive.DocumentElement.ChildNodes){if($r.id){$additiveIds[[string]$r.id]=$true}}
    $buffs=[xml](Get-Content -LiteralPath (Join-Path $Root 'unityserver/config/xml/skill_buff.xml') -Raw -Encoding UTF8)
    foreach($r in $buffs.DocumentElement.ChildNodes) { if($r.id){$buffIds[[string]$r.id]=$true;$buffNames[[string]$r.id]=[string]$r.name} }
    # Protocol-defined internal buffs have no visual/config row.
    $buffIds['193']=$true
    $buffIds['191']=$true
    $effectFields+=@('source_attack_type','tactic_used','affix_value1','affix_value2','affix_tier','affix_duration','affix_is_owner','skill_level')
    $events+=@('before_opening_action','after_passive_targets','before_thorns_roll','before_thorns_amount','opening_branch_rage','opening_branch_guard','opening_rage','before_tactic_cost','action_end','after_combo','after_skill_heal','finalize_heal','before_passive_revive','after_self_revive','before_skill_usefulness')
    $events+=@('after_thorns','after_direct_kill','after_owned_shield_loss','after_received_shield_loss','after_self_shield','before_share_damage','after_guard_damage')
    $events+=@('after_buff','after_shield_break','after_enemy_dispel','after_friendly_cleanse')
    $events+=@('after_counter_damage','after_periodic_damage')
    $events+=@('after_counter_success','after_kill_rewards','control_resisted')
    $events+=@('after_death_guard','death_observed')
    $events+=@('after_buff_removed','after_heal_with_antiheal')
    $events+=@('before_summon_attack','before_summon_hp')
    $events+=@('accepted_control','before_hp_change')
    $events+=@('after_direct_hp_loss')
    $events+=@('after_critical_roll','landed_attack')
    $events+=@('before_revive_eligibility')
    $events+=@('before_shield_passive')
    $events+=@('before_shield')
    $events+=@('after_primary_hit')
    $events+=@('before_passive_parameters','after_passive_attribute_roll','before_kill_action')
    $events+=@('kill_confirmed','accepted_kill_action','before_action_repeat')
    $events+=@('after_skill_damage','after_passive_sequence','before_passive_raw_parameters','before_buff_attempt','buff_attempt_failed','buff_attempt_applied','before_stat')
    $events+=@('before_skill_sequence','before_passive_list','before_direct_amount','before_combo_amount','before_self_damage','before_sacrifice_damage')
    $events+=@('after_landed_skill','after_dodge','secondary_attack_observed','before_protection','before_target_plan','before_counter','before_skill_growth')
    $events+=@('before_self_revive','before_skill_cast','before_kill_followup','kill_followup_damage')
    $events+=@('after_dispel_batch','after_cleanse_batch')
    $events+=@('before_effect_attempt','before_passive_value','before_thorns_damage')
    $events+=@('before_hp_restore','owned_buff_hit','passive_attempt_failed','before_debuff_resistance','after_guard_hp','before_attribute_growth','before_guard_candidate','before_guard_damage','before_passive_heal','after_hp_observed','opening_snapshot','before_attribute_transfer','before_periodic_proc','after_periodic_proc')
    $contextFields.before_kill_followup=@('action_kind')
    $contextFields.kill_followup_damage=@('amount')
    $ops+=@('extend_origin_buffs','trigger_periodic','extend_owned_buff','reserve_overheal','split_heal','consume_periodic','promote_buff','cleanse','dispel','strike','apply_skill_passives')
    $ops+=@('replace_buff','replace_passive_list','state_set','state_add','mark')
    $effectFields+=@('sequence_fixed','sequence_index','sequence_target_index')
    foreach($context in @('before_buff','before_buff_attempt','before_passive_parameters','before_passive_raw_parameters','before_shield_damage')){$contextFields[$context]+= @(1..5|ForEach-Object {'parameter_value_'+$_})}
    $ops+=@('add_parameter_flat','add_event_bonus','passive_damage')
    $contextFields.after_buff=@('event_duration','event_stack_group','event_stack_count')
    $effectFields+=@('source_base_attack','source_hp_bp_ceil')
    $effectFields+=@('event_skill','event_depth')
    $effectFields+=@($buffIds.Keys|ForEach-Object {'enemy_unstacked_units_'+$_;'enemy_unstacked_boss_'+$_;'enemy_susceptible_unstacked_'+$_;'enemy_susceptible_unstacked_boss_'+$_;'target_buff_'+$_;'target_buff_value_'+$_;'target_immune_'+$_;'target_blocks_buff_'+$_;'source_buff_'+$_;'source_owns_buff_'+$_;'enemy_buff_units_'+$_;'target_owned_buff_instances_'+$_;'target_owned_buff_remaining_'+$_})
    $effectFields+='enemies_shielded'
    $effectFields+=@($Tables.combat_effect|Where-Object {$_.op -in @('state_set','state_add')}|ForEach-Object {'state_value_'+$_.id;'target_state_value_'+$_.id})
    $effectFields+=@($Tables.combat_effect|Where-Object op -eq 'mark'|ForEach-Object {'mark_value_'+$_.id;'mark_source_'+$_.id;'mark_group_'+$_.id;'mark_present_'+$_.id;'source_mark_value_'+$_.id;'source_mark_source_'+$_.id;'source_mark_group_'+$_.id;'source_mark_present_'+$_.id})
    $effectFields+=@($skillIds.Keys|ForEach-Object {'source_skill_level_'+$_;'team_skill_level_'+$_;'source_passive_skill_'+$_})
    $effectFields+=@($heroIds.Keys|ForEach-Object {'source_team_hero_'+$_;'target_hero_'+$_})
    $effectFields+=@($Tables.combat_effect|Where-Object {$_.op -in @('gate','chance_gate')}|ForEach-Object {'gate_'+$_.id;'gate_count_'+$_.id})
    $effectFields+=@($Tables.combat_effect|Where-Object op -eq 'gate'|ForEach-Object {'counter_action_limit_'+$_.id;'counter_count_'+$_.id;'counter_age_'+$_.id;'counter_action_count_'+$_.id;'counter_turn_count_'+$_.id})
    $effectFields+=@($Tables.combat_effect|Where-Object op -eq 'gate'|ForEach-Object {'target_counter_count_'+$_.id;'target_counter_age_'+$_.id;'target_counter_action_count_'+$_.id;'target_counter_turn_count_'+$_.id})
    $effectFields+=@($Tables.combat_buff_category.category|Select-Object -Unique|ForEach-Object {'target_category_'+$_;'target_category_count_'+$_;'target_owned_periodic_raw_'+$_;'target_periodic_remaining_'+$_})
    foreach($row in $Tables.combat_effect) {
        foreach($field in (@($row.basis,$row.cap_basis,$row.growth_basis,$row.basis_cap)+@($row.conditions|ForEach-Object {$_.field;$_.value_field}))) {
            if($field -cmatch '^source_active_buff_([1-9][0-9]*)_([1-9][0-9]*)$') {
                if(-not $skillIds.ContainsKey($Matches[1]) -or -not $buffIds.ContainsKey($Matches[2])){throw 'Invalid active origin buff reference'}
                $effectFields+=$field
            }
        }
    }
    $effectFields+=@('event_target_position')
    $effectFields+=@($effectFields|Where-Object {$_ -like 'target_*' -and $_ -notlike 'target_counter_*' -and $_ -notlike 'target_state_*'}|ForEach-Object {'event_'+$_})
    $events+=@('before_guard','before_critical','before_received_heal','before_defense','after_attack','battle_begin','kill','counter_kill','before_attack')
    $ops+=@('combine_remaining','gate','chance_gate','add_duration','extend_buff','copy_buff','reset_counter')
    $targets+=@('target_any','self_any','lowest_enemy_hp','lowest_other_ally','other_allies','first_unstacked_enemy')
    $targets+=@('attacker')
    $targets+=@('first_unstacked_susceptible_enemy','same_row_enemies')
    $targets+=@('lowest_ally_current_hp','lowest_other_ally_current_hp','highest_other_ally_base_attack','first_other_enemy','lowest_other_enemy_current_hp')
    $targets+=@('other_healed_allies','lowest_two_other_healed_allies','highest_enemy_base_attack')
    $eventPolicies=@{}
    foreach($r in $Tables.combat_event_policy){
        if($r.event -notin $events -or $r.extra_depth -lt 0 -or $r.extra_depth -gt 7 -or [string]::IsNullOrWhiteSpace($r.description)){throw 'Invalid combat event policy'}
        if($eventPolicies.ContainsKey($r.event)){throw 'Conflicting event policy'}
        $eventPolicies[$r.event]=$true
    }
    function Assert-Conditions($Rows,$Fields) {
        foreach($c in $Rows) {
            if($c.Contains('value_field') -and $c.value_field -cnotin $Fields){throw 'Invalid combat comparison field'}
            if($c.field -cnotin $fields -or $c.op -cnotin @('eq','ne','lt','le','gt','ge') -or
                $null -eq $c.value -or [string]$c.value -notmatch '^-?\d+$' -or [decimal]$c.value -lt [int]::MinValue -or [decimal]$c.value -gt [int]::MaxValue) { throw "Invalid combat condition: $(ConvertTo-Json $c -Compress)" }
        }
    }
    function Describe($Row,$GearValue=$null,$AffixValues=$null) {
        $text=[string]$Row.description_template
        $values=@{}
        foreach($key in $Row.Keys) { $values[$key]=[string]$Row[$key] }
        foreach($budget in @('per_turn','per_battle','per_action','unique_targets')){if($Row.Contains($budget) -and $Row[$budget] -eq 0){$values[$budget]='不限'}}
        $values.amount_limit_label=if($Row.Contains('amount_budget') -and $Row.amount_budget -eq 'source_turn'){'每回合累计尝试恢复'}else{'单次恢复'}
        if($Row.Contains('duration_source') -and $Row.duration_source -eq 'event_duration'){$values.duration='原效果剩余'}
        foreach($key in @('affix_value1','affix_value2','affix_duration')) {
            $value=if($null -ne $AffixValues){[decimal]$AffixValues[$key]}else{0}
            if($Row.basis -eq $key){$value=$value*$Row.ratio_bp/10000+$Row.flat}
            elseif($Row.ratio_source -eq $key){$value=[decimal]::Truncate($value*$Row.ratio_bp/$Row.ratio_divisor)/10000}
            $values[$key]=if($null -eq $AffixValues){'词条配置'}else{$value.ToString([Globalization.CultureInfo]::InvariantCulture)}
            $values[$key+'_pct']=if($null -eq $AffixValues){'词条配置'}else{($value/100).ToString([Globalization.CultureInfo]::InvariantCulture)}
        }
        $gearFlat=if($Row.basis -eq 'gear_value'){$Row.flat}else{0}
        $gearDivisor=if($Row.ratio_source -eq 'gear_value'){$Row.ratio_divisor}else{10000}
        $values.gear_value=if($null -eq $GearValue){'配置曲线'}else{([decimal]$GearValue*$Row.ratio_bp/$gearDivisor+$gearFlat).ToString([Globalization.CultureInfo]::InvariantCulture)}
        $values.gear_value_pct=if($null -eq $GearValue){'配置曲线'}else{(([decimal]$GearValue*$Row.ratio_bp/$gearDivisor+$gearFlat)/100).ToString([Globalization.CultureInfo]::InvariantCulture)}
        if($Row.Contains('ratio_bp')) {
            $values.ratio_factor=([decimal]$Row.ratio_bp/10000).ToString([Globalization.CultureInfo]::InvariantCulture)
            $values.ratio_pct=([decimal]$Row.ratio_bp/100).ToString([Globalization.CultureInfo]::InvariantCulture)
            $values.ratio_output_bp_pct=([decimal]$Row.ratio_bp/1000000).ToString([Globalization.CultureInfo]::InvariantCulture)
            # coefficient_pct describes a ratio applied to HP/damage; affix_*_pct
            # above describes the output per basis unit (e.g. one combo index).
            $coefficient=[decimal]$Row.ratio_bp
            if($Row.ratio_source -eq 'gear_value'){$coefficient=if($null -eq $GearValue){$null}else{$coefficient*[decimal]$GearValue/$Row.ratio_divisor}}
            elseif($Row.ratio_source -like 'affix_*'){$coefficient=if($null -eq $AffixValues){$null}else{$coefficient*[decimal]$AffixValues[$Row.ratio_source]/$Row.ratio_divisor}}
            $values.coefficient_pct=if($null -eq $coefficient){'配置比例'}else{([decimal]::Truncate($coefficient)/100).ToString([Globalization.CultureInfo]::InvariantCulture)}
            $cap=[decimal]$Row.cap_bp
            if($Row.cap_ratio_source -eq 'gear_value'){$cap=if($null -eq $GearValue){$null}else{$cap*[decimal]$GearValue/10000}}
            elseif($Row.cap_ratio_source -like 'affix_*'){$cap=if($null -eq $AffixValues){$null}else{$cap*[decimal]$AffixValues[$Row.cap_ratio_source]/10000}}
            if($null -ne $cap){$cap=[decimal]::Truncate($cap)}
            $values.cap_pct=if($null -eq $cap){'配置上限'}else{($cap/100).ToString([Globalization.CultureInfo]::InvariantCulture)}
            $values.cap_limit_label=if($null -eq $cap){'配置上限'}elseif($cap -eq 0){'不限'}else{($cap/100).ToString([Globalization.CultureInfo]::InvariantCulture)+'%'}
            $values.cap_factor=if($null -eq $cap){'配置上限'}else{($cap/10000).ToString([Globalization.CultureInfo]::InvariantCulture)}
            $values.flat_bp_pct=([decimal]$Row.flat/100).ToString([Globalization.CultureInfo]::InvariantCulture)
            $probability=[decimal]$Row.probability_bp
            if($Row.Contains('probability_source') -and $Row.probability_source -ne 'constant'){$probability=if($null -eq $AffixValues){$null}else{[decimal]::Truncate($probability*[decimal]$AffixValues[$Row.probability_source]/10000)}}
            $values.probability_pct=if($null -eq $probability){'配置概率'}else{($probability/100).ToString([Globalization.CultureInfo]::InvariantCulture)}
            $values.growth_pct=([decimal]$Row.growth_bp/100).ToString([Globalization.CultureInfo]::InvariantCulture)
        }
        if($Row.Contains('bonus_bp')) { $values.bonus_pct=([decimal]$Row.bonus_bp/100).ToString([Globalization.CultureInfo]::InvariantCulture) }
        $values.basis_cap_value='不限'
        if($Row.basis_cap -and $Row.basis_cap -ne 'none') {
            $limit=if($null -ne $AffixValues -and $AffixValues.ContainsKey($Row.basis_cap)){$AffixValues[$Row.basis_cap]}else{$null}
            $values.basis_cap_value=if($null -eq $limit){'配置上限'}elseif([decimal]$limit -gt 0){[string]$limit}else{'不限'}
        }
        $conditions=@(foreach($c in $Row.conditions) {
            $comparison=if($c.Contains('value_field')){$values[$c.value_field]}else{[string]$c.value}
            $values['condition_'+$c.field]=$comparison
            $values['condition_'+$c.field+'_'+$c.op]=[string]$c.value
            $values['condition_'+$c.field+'_one_based']=[string]([long]$c.value+1)
            $values['condition_'+$c.field+'_pct']=([decimal]$c.value/100).ToString([Globalization.CultureInfo]::InvariantCulture)
            '{0} {1} {2}' -f $c.field,$c.op,$c.value
        })
        $values.conditions_text=if($conditions.Count){$conditions -join ' 且 '}else{'无'}
        foreach($key in $values.Keys){$text=$text.Replace('{'+$key+'}',$values[$key])}
        $text=$text -replace '最多\s*(尝试|触发|成功)?\s*不限\s*次','$1次数不限'
        if([string]::IsNullOrWhiteSpace($text) -or $text -match '\{[^}]*\}') { throw "Unresolved combat description: $text" }
        $Row['description']=$text
    }
    $categories=@{}
    foreach($r in $Tables.combat_buff_category){
        if(-not $buffIds.ContainsKey([string]$r.buff_id) -or $r.category -lt 1 -or $r.category -gt 65535 -or $categories.ContainsKey([string]$r.buff_id)){throw 'Invalid or conflicting buff category'}
        $categories[[string]$r.buff_id]=$r.category
    }
    $groups=@{}; $stackContracts=@{}; $affixContracts=@{}; $affixGroups=@{}
    function Get-SourceCounterRecord([long]$CounterId,[string]$Scope='source') {
        $record=@($Tables.combat_effect|Where-Object id -eq $CounterId)
        if($record.Count -ne 1 -or $record[0].op -cne 'gate' -or $record[0].counter_scope -cne $Scope){throw 'Invalid persistent counter reference'}
        return $record[0]
    }
    foreach($r in $Tables.combat_effect) {
        if($r.duration -eq -1) {
            $source=@($Tables.equipment_affix|Where-Object id -eq $r.affix_id)
            if(-not $r.affix_id -or $source.Count -ne 1){throw 'Inherited duration requires a valid affix binding'}
            $duration=$source[0].duration
            if($null -eq $duration -or [decimal]$duration -ne [long]$duration -or $duration -lt 1 -or $duration -gt 255){throw 'Invalid inherited affix duration'}
            $r.duration=[long]$duration
        }
        foreach($budget in @(@('per_turn','per_turn_limit'),@('per_battle','per_battle_limit'))) {
            if($r[$budget[0]] -eq -1) {
                $source=@($Tables.equipment_affix|Where-Object id -eq $r.affix_id)
                if(-not $r.affix_id -or $source.Count -ne 1){throw 'Inherited budget requires a valid affix binding'}
                $limit=$source[0][$budget[1]]
                if($null -eq $limit -or [decimal]$limit -ne [long]$limit -or $limit -lt 0 -or $limit -gt 65535){throw 'Invalid inherited affix budget'}
                $r[$budget[0]]=[long]$limit
            }
        }
        $fields=$effectFields + @($contextFields[$r.event])
        if(-not $r.Contains('duration_source')){$r.duration_source='constant'}
        if(-not $r.Contains('amount_budget')){$r.amount_budget='none'}
        if(-not $r.Contains('binding_scope')){$r.binding_scope='owner'}
        if($r.binding_scope -cnotin @('owner','target_team','source_mark','target_mark','source_buff_owner') -or ($r.binding_scope -eq 'target_team' -and (-not (($r.event -eq 'before_shield' -and $r.op -eq 'add_amount_bonus') -or ($r.event -eq 'before_stat' -and $r.op -eq 'multiply_amount')) -or $r.skill_id -ne 0 -or $r.affix_id -ne 0))){throw 'Invalid team binding modifier'}
        if($r.target -eq 'attacker' -and $r.event -ne 'shield_lost'){throw 'Attacker selector requires shield loss'}
        if($r.op -in @('cleanse','dispel') -and ($r.argument -or $r.duration -or $r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.cap_bp -or $r.flat -le 0 -or $r.flat -gt 65535)){throw 'Invalid buff removal operation'}
        if($r.op -eq 'strike' -and ($r.event -ne 'after_primary_hit' -or $r.argument -gt 2 -or $r.duration -or $r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.cap_bp -or $r.flat -le 0)){throw 'Invalid computed strike operation'}
        if($r.op -eq 'apply_skill_passives' -and ($r.event -ne 'after_primary_hit' -or -not $skillIds.ContainsKey([string]$r.argument) -or $r.duration)){throw 'Invalid skill passive operation'}
        if($r.op -eq 'promote_buff' -and ($r.event -ne 'after_counter_success' -or $r.target -ne 'target' -or -not $buffIds.ContainsKey([string]$r.argument) -or $r.origin_skill -le 0 -or $r.presentation_skill -le 0 -or $r.emit_action -or $r.duration -or $r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.cap_bp -or $r.flat -le 0)){throw 'Invalid buff promotion operation'}
        if($r.op -eq 'consume_periodic' -and ($r.event -ne 'after_landed_skill' -or $r.target -ne 'target' -or -not $buffIds.ContainsKey([string]$r.argument) -or -not @($Tables.combat_periodic|Where-Object buff_id -eq $r.argument).Count -or $r.basis -cne ('target_owned_buff_remaining_'+$r.argument) -or $r.probability_bp -ne 10000 -or $r.duration -or $r.flat -or $r.growth_bp -or $r.budget -ne 'none')){throw 'Invalid periodic consumption operation'}
        if($r.op -eq 'trigger_periodic' -and ($r.event -ne 'after_landed_skill' -or $r.target -ne 'target' -or -not @($Tables.combat_periodic|Where-Object {$_.buff_id -eq $r.argument -and $_.outcome -eq 'damage'}).Count -or $r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.cap_bp -or $r.duration -or $r.flat -lt 0 -or $r.budget -ne 'none')){throw 'Invalid periodic trigger operation'}
        if($r.op -eq 'extend_owned_buff' -and ($r.event -ne 'after_periodic_proc' -or $r.target -ne 'target' -or -not $buffIds.ContainsKey([string]$r.argument) -or $r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.cap_bp -or $r.duration -lt 1 -or $r.flat -lt 0 -or $r.probability_bp -ne 10000 -or $r.budget -ne 'none')){throw 'Invalid owned buff extension'}
        if($r.op -eq 'reserve_overheal' -and ($r.event -ne 'after_heal' -or $r.target -ne 'self_any' -or $r.basis -ne 'overheal' -or $r.ratio_bp -lt 0 -or $r.ratio_bp -gt 10000 -or $r.argument -or $r.flat -or $r.duration -or $r.cap_bp -or $r.growth_bp -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.per_action -or $r.interval_turns -or $r.unique_targets -or $r.budget -ne 'none')){throw 'Invalid overheal reservation'}
        if($r.op -eq 'split_heal' -and ($r.event -ne 'after_heal' -or $r.target -notin @('other_healed_allies','lowest_two_other_healed_allies') -or $r.basis -ne 'overheal' -or $r.argument -or $r.flat -or $r.duration -or $r.growth_bp -or $r.probability_bp -ne 10000 -or $r.budget -ne 'none')){throw 'Invalid healing distribution'}
        if($r.target -in @('other_healed_allies','lowest_two_other_healed_allies') -and $r.op -ne 'split_heal'){throw 'Healing distribution selector requires split healing'}
        if(($r.op -eq 'passive_damage' -and $r.event -notin @('after_guard_hp','kill_followup_damage','shield_lost','after_primary_hit','after_dodge','after_landed_skill')) -or ($r.op -eq 'add_event_bonus' -and $r.event -ne 'shield_lost')){throw 'Shield result operation requires shield loss'}
        if($r.op -eq 'add_event_bonus' -and ($r.target -ne 'self' -or $r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.cap_bp -or $r.flat -lt 0 -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.interval_turns -or $r.per_action -or $r.unique_targets -or $r.budget -ne 'none')){throw 'Invalid event coefficient addition'}
        if($r.op -eq 'add_parameter_flat' -and ($r.event -notin @('before_attribute_growth','before_buff','before_shield','before_passive_parameters','before_passive_raw_parameters','before_buff_attempt','before_critical') -or $r.target -ne 'target' -or $r.argument -lt 0 -or $r.argument -gt $(if($r.event -eq 'before_passive_raw_parameters'){4}elseif($r.event -eq 'before_critical'){1}else{3}) -or ($r.event -ne 'before_buff_attempt' -and ($r.basis -ne 'one' -or $r.ratio_bp)) -or $r.growth_bp -or $r.cap_bp -or ($r.event -eq 'before_shield' -and $r.flat -lt 0))){throw 'Invalid parameter addition'}
        if($r.op -in @('state_set','state_add') -and (($r.counter_scope -eq 'source' -and $r.target -notin @('self','self_any')) -or ($r.counter_scope -eq 'target' -and $r.target -notin @('target','target_any')) -or $r.counter_scope -eq 'team' -or $r.duration -or $r.probability_bp -ne 10000 -or $r.budget -ne 'none' -or $r.cap_bp)){throw 'Invalid numeric state operation'}
        if($r.op -eq 'mark' -and ($r.binding_scope -ne 'owner' -or $r.argument -or $r.probability_bp -ne 10000 -or $r.budget -ne 'none' -or $r.counter_scope -ne 'source')){throw 'Invalid timed mark operation'}
        if($r.event -eq 'before_shield' -and ($r.op -notin @('add_amount_bonus','add_parameter_flat','add_duration') -or $r.probability_bp -ne 10000 -or $r.budget -ne 'none' -or ($r.binding_scope -eq 'target_team' -and ($r.per_turn -or $r.per_battle -or $r.interval_turns -or $r.per_action -or $r.unique_targets)))){throw 'Shield query must be deterministic'}
        if($r.target -in @('first_unstacked_enemy','first_unstacked_susceptible_enemy') -and $r.event -notin @('after_buff','buff_attempt_applied')){throw 'Stack selector requires after_buff'}
        if($r.target -eq 'same_row_enemies' -and $r.event -ne 'buff_attempt_applied'){throw 'Row selector requires an applied buff event'}
        if(-not $r.Contains('parameter_count')){$r.parameter_count=1}
        if($r.parameter_count -notin @(0,1,2,3,4) -or ($r.op -eq 'copy_buff' -and $r.parameter_count -ne 0) -or ($r.op -eq 'buff' -and $r.parameter_count -eq 0 -and ($r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.flat -or $r.cap_bp)) -or ($r.op -notin @('buff','copy_buff') -and $r.parameter_count -ne 1)){throw 'Invalid buff parameter count'}
        foreach($field in @('query_effect','query_attribute','query_parameter','query_level')){if(-not $r.Contains($field)){$r[$field]=0}}
        if($r.query_effect -lt 0 -or $r.query_effect -gt 65535 -or $r.query_attribute -lt 0 -or $r.query_attribute -gt 65535 -or $r.query_parameter -lt 0 -or $r.query_parameter -gt 3 -or $r.query_level -lt 0 -or $r.query_level -gt 65535){throw 'Invalid passive attribute parameter source'}
        if($r.query_effect) {
            if($r.op -ne 'buff' -or -not $additiveIds.ContainsKey([string]$r.query_effect) -or $r.query_attribute -lt 101 -or $r.query_attribute -gt 120 -or $r.query_parameter -ge $r.parameter_count){throw 'Invalid passive attribute parameter source'}
        } elseif($r.query_attribute -or $r.query_parameter -or $r.query_level){throw 'Invalid passive attribute parameter source'}
        if(-not $r.Contains('origin_level')){$r.origin_level=0}
        if($r.origin_level -lt 0 -or $r.origin_level -gt 65535 -or [decimal]$r.origin_level -ne [long]$r.origin_level -or ($r.origin_level -ne 0 -and $r.op -notin @('buff','copy_buff','shield'))){throw 'Invalid buff origin level'}
        if(-not $r.Contains('origin_skill')){$r.origin_skill=-1}
        if($r.origin_skill -lt -1 -or $r.origin_skill -gt 65535 -or [decimal]$r.origin_skill -ne [long]$r.origin_skill -or ($r.origin_skill -ge 0 -and $r.op -notin @('promote_buff','buff','copy_buff','shield'))){throw 'Invalid buff origin skill'}
        if(-not $r.Contains('probability_source')){$r.probability_source='constant'}
        if($r.probability_source -cnotin @('constant','affix_value1','affix_value2')){throw 'Invalid probability source'}
        if($r.probability_source -ne 'constant') {
            $affix=@($Tables.equipment_affix|Where-Object id -eq $r.affix_id)
            if($r.op -ne 'chance_gate' -or -not $r.affix_id -or $affix.Count -ne 1){throw 'Invalid dynamic probability contract'}
            $curve=$affix[0][($r.probability_source -replace '^affix_','')]
            if($curve.Count -ne 3 -or @($curve|Where-Object {[decimal]$_ -lt 0 -or [decimal]$_ -ne [long]$_ -or [decimal]::Truncate([decimal]$_*$r.probability_bp/10000) -gt 10000}).Count){throw 'Invalid dynamic probability range'}
        }
        if($r.amount_budget -cnotin @('none','source_turn','source_action') -or ($r.amount_budget -ne 'none' -and ($r.op -notin @('rage','heal','restore_hp','damage','shield') -or $r.counter_scope -ne 'source' -or $r.cap_bp -le 0))){throw 'Invalid amount budget contract'}
        if(-not $r.Contains('emit_action')){$r.emit_action=1}
        if($r.emit_action -notin @(0,1) -or (-not $r.emit_action -and $r.op -notin @('promote_buff','buff','copy_buff','shield'))){throw 'Silent effect requires buff or shield operation'}
        if(-not $r.Contains('check_skill_immunity')){$r.check_skill_immunity=1}
        if($r.check_skill_immunity -notin @(0,1) -or (-not $r.check_skill_immunity -and $r.op -notin @('buff','copy_buff'))){throw 'Invalid skill immunity policy'}
        if($r.duration_source -notin @('constant','event_duration') -or ($r.duration_source -ne 'constant' -and ($r.op -notin @('shield','buff','copy_buff') -or $r.duration_source -notin $fields -or $r.duration))){throw 'Invalid dynamic duration source'}
        if($r.op -eq 'copy_buff' -and ($r.event -notin @('after_buff','buff_attempt_applied') -or $r.argument -or $r.duration_source -ne 'event_duration' -or $r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.flat -or $r.cap_bp)){throw 'Invalid buff copy contract'}
        if($r.affix_id -lt 0 -or ($r.affix_id -gt 0 -and $r.affix_id -notin @($Tables.equipment_affix.id)) -or $r.affix_scope -cnotin @('owner','team_highest','team_highest_value2') -or $r.affix_alive_only -notin @(0,1)){throw 'Invalid effect affix binding'}
        $key=[string]$r.group_id;$signature="$($r.affix_id):$($r.affix_scope):$($r.affix_alive_only)"
        if($affixContracts.ContainsKey($key) -and $affixContracts[$key] -ne $signature){throw 'Conflicting effect group affix binding'}
        $affixContracts[$key]=$signature
        if($r.affix_id){$affixGroups[$key]=$true}
        foreach($field in @($r.basis,$r.cap_basis,$r.growth_basis,$r.basis_cap,$r.ratio_source,$r.cap_ratio_source)+@($r.conditions|ForEach-Object {$_.field;if($_.Contains('value_field')){$_.value_field}})){
            if($field -match '^counter_(?:action_limit|count|age|action_count|turn_count)_([1-9][0-9]*)$'){$null=Get-SourceCounterRecord ([long]$Matches[1])}
            if($field -match '^target_counter_(?:count|age|action_count|turn_count)_([1-9][0-9]*)$'){$null=Get-SourceCounterRecord ([long]$Matches[1]) 'target'}
            if($field -eq 'effect_battle_count' -and $r.counter_scope -ne 'source'){throw 'Effect count requires source scope'}
            if(-not $r.affix_id -and $field -like 'affix_*'){throw 'Affix fact requires affix binding'}
            if($field -match '^gate_(?:count_)?([1-9][0-9]*)$'){
                $gate=$Tables.combat_effect|Where-Object id -eq ([long]$Matches[1])
                if(-not $gate -or $gate.op -notin @('gate','chance_gate') -or $gate.group_id -ne $r.group_id -or $gate.event -ne $r.event -or $gate.priority -gt $r.priority -or ($gate.priority -eq $r.priority -and $gate.id -ge $r.id)){throw 'Invalid or cyclic event gate reference'}
            }
        }
        if($r.growth_basis -cnotin $fields){throw 'Unavailable growth basis'}
        if($r.basis_cap -ne 'none' -and $r.basis_cap -cnotin $fields){throw 'Unavailable basis cap'}
        if($r.ratio_divisor -lt 1 -or $r.ratio_divisor -gt 1000000 -or [decimal]$r.ratio_divisor -ne [long]$r.ratio_divisor){throw 'Invalid coefficient divisor'}
        if($r.ratio_source -eq 'constant' -and $r.ratio_divisor -ne 10000){throw 'Constant coefficient cannot use a dynamic divisor'}
        if($r.cap_ratio_source -notin @('constant','gear_value','affix_value1','affix_value2')){throw 'Invalid combat cap ratio source'}
        if($r.cap_ratio_source -ne 'constant' -and -not $r.cap_bp){throw 'Dynamic cap requires positive cap coefficient'}
        if($r.argument_role -notin @('fixed','regular','tactic','all') -or ($r.argument_role -ne 'fixed' -and ($r.op -ne 'cooldown' -or $r.argument))){throw 'Invalid skill role argument'}
        if($r.op -eq 'gate' -and ($(if($r.counter_scope -eq 'target'){$r.target -notin @('target','target_any')}else{$r.target -notin @('self','self_any')}) -or $r.probability_bp -ne 10000 -or $r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.flat -or $r.cap_bp -or $r.duration -or $r.argument)){throw 'Invalid event gate'}
        if($r.op -eq 'chance_gate' -and ($(if($r.counter_scope -eq 'target'){$r.target -notin @('target','target_any')}else{$r.target -notin @('self','self_any')}) -or $r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.flat -or $r.cap_bp -or $r.duration -or $r.argument -or $r.budget -ne 'none')){throw 'Invalid chance gate'}
        if($r.op -eq 'reset_counter') {
            if($r.argument -le 0 -or $r.argument -gt [int]::MaxValue -or [decimal]$r.argument -ne [long]$r.argument -or $r.target -notin @('self','self_any') -or $r.counter_scope -ne 'source' -or $r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.flat -or $r.cap_bp -or $r.duration -or $r.probability_bp -ne 10000 -or $r.probability_source -ne 'constant' -or $r.per_turn -or $r.per_battle -or $r.interval_turns -or $r.per_action -or $r.unique_targets -or $r.budget -ne 'none'){throw 'Invalid state reset operation'}
            $null=Get-SourceCounterRecord ([long]$r.argument)
        }
        if($r.op -eq 'add_duration' -and ($r.event -notin @('accepted_control','before_shield','before_buff_attempt') -or $r.target -ne 'target' -or $r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.cap_bp -or $r.flat -lt 0 -or $r.flat -gt 255 -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.interval_turns -or $r.per_action -or $r.unique_targets -or $r.budget -ne 'none')){throw 'Invalid duration addition'}
        if($r.event -eq 'accepted_control' -and $r.op -notin @('gate','chance_gate','add_duration')){throw 'Accepted control requires gates or duration addition'}
        if($r.budget -notin @('none','extra_attack')) { throw "Invalid combat budget: $($r.id)" }
        if($r.counter_scope -cnotin @('source','target','team')){throw "Invalid combat counter scope: $($r.id)"}
        if($r.ratio_source -notin @('constant','gear_value','affix_value1','affix_value2','event_bonus') -or $r.interval_turns -lt 0 -or $r.interval_turns -gt 65535 -or $r.counter_key -lt 0){throw "Invalid combat coefficient/interval/counter: $($r.id)"}
        if($r.ratio_source -eq 'event_bonus' -and ($r.event -ne 'shield_lost' -or $r.op -ne 'passive_damage')){throw 'Invalid event bonus consumer'}
        if($r.id -le 0 -or $r.group_id -le 0 -or $r.priority -lt 0 -or $r.event -cnotin $events -or $r.op -cnotin $ops -or $r.target -cnotin $targets -or $r.basis -cnotin $fields -or $r.cap_basis -cnotin $fields) { throw "Invalid combat effect vocabulary: $($r.id)" }
        $ratioLimit=if($r.basis -cmatch '^source_skill_level_[1-9][0-9]*$' -and (($r.event -eq 'before_counter' -and $r.op -eq 'set_parameter') -or ($r.event -eq 'before_periodic_proc' -and $r.op -eq 'add_amount_bonus'))){10000000}else{1000000}
        if($r.probability_bp -lt 0 -or $r.probability_bp -gt 10000 -or $r.duration -lt 0 -or $r.duration -gt 255 -or $r.per_turn -lt 0 -or $r.per_turn -gt 65535 -or $r.per_battle -lt 0 -or $r.per_battle -gt 65535 -or [Math]::Abs($r.ratio_bp) -gt $ratioLimit -or [Math]::Abs($r.growth_bp) -gt 10000 -or [Math]::Abs($r.flat) -gt 1000000 -or $r.cap_bp -lt 0 -or $r.cap_bp -gt 1000000) { throw "Invalid combat effect range: $($r.id)" }
        if(($r.skill_id -ne 0 -and -not $skillIds.ContainsKey([string]$r.skill_id)) -or ($r.origin_skill -gt 0 -and -not $skillIds.ContainsKey([string]$r.origin_skill) -and -not $gearOrigins.ContainsKey("$($r.group_id):$($r.origin_skill)")) -or ($r.buff_id -ne 0 -and -not $buffIds.ContainsKey([string]$r.buff_id)) -or ($r.op -in @('buff','extend_buff','replace_buff') -and -not $buffIds.ContainsKey([string]$r.argument)) -or ($r.op -eq 'cooldown' -and $r.argument_role -eq 'fixed' -and -not $skillIds.ContainsKey([string]$r.argument))) { throw "Unknown combat effect skill/buff: $($r.id)" }
        if(($r.op -in @('buff','shield') -and $r.duration_source -eq 'constant' -and $r.duration -le 0) -or ($r.op -in @('set_duration','scale_parameters') -and $r.event -notin @('before_buff','before_buff_attempt')) -or ($r.op -eq 'scale_amount' -and $r.event -notin @('before_opening_action','before_passive_heal','before_attribute_transfer','before_periodic_proc','after_periodic_proc','before_passive_value','before_kill_followup','before_self_revive','before_dot','finalize_heal','before_passive_revive','before_passive_parameters','after_passive_attribute_roll','before_buff_attempt','before_passive_list','before_self_damage')) -or ($r.op -in @('set_duration','scale_parameters','scale_amount') -and $r.target -ne 'target') -or ($r.op -eq 'cooldown' -and $r.target -notin @('self','self_any')) -or ($r.op -eq 'rage' -and $r.target -notin @('self','self_any','highest_gear_ally'))) { throw "Incompatible combat effect: $($r.id)" }
        if($r.event -eq 'before_opening_action' -and ($r.op -ne 'scale_amount' -or $r.target -ne 'target' -or $r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.cap_bp -or $r.flat -lt 0 -or $r.flat -gt 1 -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.per_action -or $r.interval_turns -or $r.unique_targets -or $r.budget -ne 'none' -or $r.duration)){throw 'Invalid opening action plan'}
        if($r.op -eq 'set_duration' -and ($r.basis -ne 'one' -or $r.ratio_bp -ne 0 -or $r.growth_bp -ne 0 -or $r.flat -lt 0 -or $r.flat -gt 255)){throw "Invalid duration modifier: $($r.id)"}
        if($r.op -eq 'combine_remaining' -and ($r.event -ne 'before_defense' -or $r.target -ne 'target')){throw 'Invalid remaining fraction modifier'}
        if($r.op -eq 'combine_remaining' -and ($r.ratio_source -ne 'constant' -or $r.growth_bp -or $r.cap_bp -or -not $(if($r.basis -in @('gear_value','affix_value1')){$r.ratio_bp -ge 0 -and $r.ratio_bp -le 10000 -and -not $r.flat}else{$r.basis -eq 'one' -and -not $r.ratio_bp -and $r.flat -ge 0 -and $r.flat -le 10000}))){throw 'Invalid remaining fraction coefficient'}
        if($r.event -in @('before_guard','before_defense','before_received_heal') -and ($r.op -ne $(if($r.event -eq 'before_defense'){'combine_remaining'}else{'add_amount_bonus'}) -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.interval_turns -or $r.per_action -or $r.unique_targets -or $r.budget -ne 'none')){throw 'Stat query must be a deterministic modifier'}
        if($r.event -eq 'before_critical' -and ($r.op -notin @('add_amount_bonus','set_parameter','add_parameter_flat') -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.interval_turns -or $r.per_action -or $r.unique_targets -or $r.budget -ne 'none' -or ($r.op -eq 'set_parameter' -and ($r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.cap_bp -or $r.flat -lt 0 -or $r.flat -gt 1)))){throw 'Invalid critical plan'}
        if(($r.op -eq 'add_amount_bonus' -and $r.event -notin @('before_thorns_roll','owned_buff_hit','before_debuff_resistance','before_share_damage','before_periodic_proc','before_dot','before_heal','before_direct_damage','before_action_order','before_shield_damage','before_guard','before_critical','before_received_heal','before_attack','before_tactic_cost','before_summon_attack','before_summon_hp','landed_attack','before_shield','before_buff_attempt')) -or ($r.op -eq 'add_parameter_bonus' -and $r.event -notin @('before_buff','before_attack','before_passive_parameters','before_passive_raw_parameters','before_buff_attempt')) -or ($r.op -in @('add_amount_bonus','add_parameter_bonus') -and $r.target -ne 'target')){throw "Invalid combat bonus modifier: $($r.id)"}
        if($r.event -in @('before_summon_attack','before_summon_hp') -and ($r.op -ne 'add_amount_bonus' -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.interval_turns -or $r.per_action -or $r.unique_targets -or $r.budget -ne 'none')){throw 'Summon query must be a deterministic modifier'}
        if($r.event -eq 'before_attack' -and ($r.op -notin @('add_amount_bonus','add_parameter_bonus') -or $r.argument -gt 2 -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.interval_turns -or $r.per_action -or $r.unique_targets -or $r.budget -ne 'none')){throw 'Attack query must be a deterministic stat modifier'}
        if($r.per_action -lt 0 -or $r.per_action -gt 65535 -or $r.unique_targets -lt 0 -or $r.unique_targets -gt 65535 -or ($r.per_action -gt 0 -and $r.counter_scope -eq 'team') -or ($r.unique_targets -gt 0 -and $r.counter_scope -ne 'source')){throw 'Invalid action budget scope/range'}
        if($r.op -eq 'set_parameter' -and ($r.event -notin @('after_passive_targets','before_attribute_growth','before_guard_candidate','before_passive_heal','before_periodic_proc','before_effect_attempt','before_kill_followup','before_self_revive','before_skill_growth','before_counter','before_target_plan','before_protection','before_buff','before_shield_damage','finalize_heal','before_skill_usefulness','before_revive_eligibility','before_shield_passive','before_passive_parameters','before_passive_raw_parameters','before_kill_action','before_action_repeat','before_buff_attempt','before_skill_sequence','before_critical','before_combo_amount','before_sacrifice_damage') -or $r.target -ne 'target' -or $r.argument -lt 0 -or $r.argument -gt $(if($r.event -eq 'before_passive_raw_parameters'){4}elseif($r.event -in @('after_passive_targets','before_attribute_growth','before_kill_followup','before_counter','before_target_plan','before_protection','before_buff','before_passive_parameters','before_buff_attempt','before_skill_sequence')){3}elseif($r.event -in @('before_passive_heal','before_sacrifice_damage')){2}elseif($r.event -in @('before_effect_attempt','before_skill_growth','before_kill_action','before_skill_usefulness')){1}else{0}))){throw 'Invalid set parameter operation'}
        if($r.event -eq 'after_passive_targets') {
            if($r.op -notin @('gate','set_parameter') -or $r.probability_bp -ne 10000 -or $r.budget -ne 'none'){throw 'Invalid passive target plan'}
            if($r.op -eq 'set_parameter') {
                $maximum=if($r.argument -eq 0){2}elseif($r.argument -eq 1){9}elseif($r.argument -eq 2){65535}else{1}
                if($r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.cap_bp -or $r.duration -or $r.per_turn -or $r.per_battle -or $r.per_action -or $r.interval_turns -or $r.unique_targets -or $r.flat -lt 0 -or $r.flat -gt $maximum -or ($r.argument -eq 2 -and $r.flat -and -not $buffIds.ContainsKey([string]$r.flat))){throw 'Invalid passive target parameter'}
            }
        }
        if($r.event -eq 'before_periodic_proc' -and $r.op -eq 'set_parameter' -and ($r.basis -ne 'one' -or $r.ratio_bp -or $r.flat -lt 0 -or $r.flat -gt 1 -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.per_action -or $r.interval_turns -or $r.unique_targets -or $r.budget -ne 'none')){throw 'Invalid periodic eligibility flag'}
        if($r.event -eq 'before_effect_attempt') {
            if($r.op -notin @('gate','set_parameter') -or $r.probability_bp -ne 10000 -or $r.budget -ne 'none'){throw 'Invalid effect attempt query'}
            if($r.op -eq 'set_parameter') {
                $validValue=if($r.argument -eq 0){$r.basis -eq 'one' -and -not $r.ratio_bp -and $r.flat -ge 0 -and $r.flat -le 1}else{($r.basis -eq 'base_duration' -and $r.ratio_bp -eq 10000 -and -not $r.flat) -or ($r.basis -eq 'one' -and -not $r.ratio_bp -and $r.flat -ge 0 -and $r.flat -le 255)}
                if(-not $validValue -or $r.per_turn -or $r.per_battle -or $r.per_action -or $r.interval_turns -or $r.unique_targets -or $r.growth_bp -or $r.cap_bp -or $r.duration){throw 'Invalid effect attempt query'}
            }
        }
        if($r.event -eq 'before_attribute_transfer' -and ($r.op -ne 'scale_amount' -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.per_action -or $r.interval_turns -or $r.unique_targets -or $r.budget -ne 'none' -or $r.duration)){throw 'Attribute transfer query must be deterministic'}
        if($r.op -eq 'extend_origin_buffs' -and ($r.event -ne 'after_periodic_damage' -or $r.target -ne 'target_any' -or -not $skillIds.ContainsKey([string]$r.argument) -or $r.flat -lt 1 -or $r.flat -gt 255 -or $r.duration -lt 1 -or $r.duration -gt 255 -or $r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.cap_bp -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.per_action -or $r.interval_turns -or $r.unique_targets -or $r.budget -ne 'none')){throw 'Invalid origin buff extension'}
        if($r.binding_scope -eq 'source_buff_owner' -and ($r.event -ne 'owned_buff_hit' -or -not $r.buff_id -or $r.op -notin @('gate','add_amount_bonus'))){throw 'Invalid source buff owner binding'}
        if($r.event -eq 'before_debuff_resistance' -and ($r.op -ne 'add_amount_bonus' -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.per_action -or $r.interval_turns -or $r.unique_targets -or $r.budget -ne 'none' -or $r.duration)){throw 'Resistance query must be deterministic'}
        if($r.event -eq 'before_attribute_growth') {
            if($r.op -notin @('set_parameter','add_parameter_flat') -or $r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.cap_bp -or $r.duration -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.per_action -or $r.interval_turns -or $r.unique_targets -or $r.budget -ne 'none'){throw 'Invalid attribute growth plan'}
            if($r.op -eq 'add_parameter_flat') {if($r.argument -ne 2){throw 'Invalid attribute growth addition'}}
            else {if($r.argument -eq 2 -or $r.flat -lt 0 -or $r.flat -gt $(if($r.argument -eq 0){65535}elseif($r.argument -eq 1){255}else{10000})){throw 'Invalid attribute growth parameter'}}
            if($r.op -eq 'set_parameter' -and $r.argument -eq 0 -and $r.flat -and -not $buffIds.ContainsKey([string]$r.flat)){throw 'Invalid attribute growth buff reference'}
        }
        if($r.event -eq 'before_guard_candidate' -and ($r.op -ne 'set_parameter' -or $r.argument -or $r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.cap_bp -or $r.flat -lt 0 -or $r.flat -gt 1 -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.per_action -or $r.interval_turns -or $r.unique_targets -or $r.budget -ne 'none' -or $r.duration)){throw 'Invalid guard candidate flag'}
        if($r.event -eq 'after_hp_observed' -and ($r.op -ne 'gate' -or $r.probability_bp -ne 10000 -or $r.budget -ne 'none')){throw 'HP observation may only record deterministic state'}
        if($r.event -eq 'before_passive_heal' -and $r.op -notin @('gate','scale_amount','multiply_amount','set_parameter','buff')){throw 'Invalid passive healing plan'}
        if($r.event -eq 'before_passive_heal' -and $r.op -in @('scale_amount','multiply_amount','set_parameter') -and ($r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.per_action -or $r.interval_turns -or $r.unique_targets -or $r.budget -ne 'none' -or $r.duration -or ($r.op -eq 'set_parameter' -and ($r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.cap_bp -or $r.argument -gt 2 -or $r.flat -lt 0 -or $r.flat -gt 1)))){throw 'Invalid passive healing modifier'}
        if($r.event -eq 'before_passive_value' -and ($r.op -notin @('scale_amount','multiply_amount') -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.per_action -or $r.interval_turns -or $r.unique_targets -or $r.budget -ne 'none' -or $r.duration)){throw 'Invalid passive value query'}
        if($r.event -eq 'before_kill_followup' -and ($r.op -notin @('gate','scale_amount','set_parameter') -or $r.probability_bp -ne 10000 -or ($r.op -ne 'gate' -and ($r.per_turn -or $r.per_battle -or $r.per_action -or $r.interval_turns -or $r.unique_targets -or $r.budget -ne 'none')) -or ($r.op -eq 'set_parameter' -and ($r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.cap_bp -or $r.flat -lt 0 -or $r.flat -gt $(if($r.argument -eq 1){1000000}else{1}))))){throw 'Invalid kill followup query'}
        if($r.event -eq 'before_self_revive' -and ($r.op -notin @('gate','scale_amount','set_parameter') -or $r.probability_bp -ne 10000 -or $r.budget -ne 'none')){throw 'Invalid self revival plan'}
        if($r.event -eq 'before_skill_growth' -and ($r.op -ne 'set_parameter' -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.per_action -or $r.interval_turns -or $r.unique_targets -or $r.budget -ne 'none' -or $r.duration -or $r.basis -ne 'one' -or $r.ratio_bp -or $r.cap_bp -or $r.growth_bp -or $r.flat -lt 0 -or $r.flat -gt 65535)){throw 'Invalid skill growth query'}
        if($r.event -eq 'before_counter' -and ($r.op -notin @('chance_gate','set_parameter') -or ($r.op -eq 'set_parameter' -and ($r.argument -gt 3 -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.per_action -or $r.interval_turns -or $r.unique_targets -or $r.budget -ne 'none' -or $r.duration -or $r.cap_bp -or $r.growth_bp)))){throw 'Invalid counter query'}
        if($r.event -eq 'before_protection' -and ($r.op -ne 'set_parameter' -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.per_action -or $r.interval_turns -or $r.unique_targets -or $r.budget -ne 'none' -or $r.duration -or $r.cap_bp -or $r.growth_bp)){throw 'Invalid protection query'}
        if($r.event -eq 'before_target_plan' -and ($r.op -ne 'set_parameter' -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.per_action -or $r.interval_turns -or $r.unique_targets -or $r.budget -ne 'none' -or $r.duration -or $r.basis -ne 'one' -or $r.ratio_bp -or $r.cap_bp -or $r.growth_bp -or $r.flat -lt 0 -or ($r.argument -eq 0 -and $r.flat -gt 2) -or ($r.argument -eq 1 -and $r.flat -gt 19) -or ($r.argument -eq 2 -and $r.flat -gt 9))){throw 'Invalid target plan query'}
        if($r.event -eq 'before_skill_sequence' -and ($r.op -notin @('set_parameter','state_set','state_add') -or $r.probability_bp -ne 10000 -or $r.budget -ne 'none' -or ($r.op -eq 'set_parameter' -and ($r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.cap_bp -or $r.flat -lt 0 -or $r.flat -gt $(if($r.argument -eq 0){255}else{1}))))){throw 'Invalid skill sequence plan'}
        if($r.event -eq 'before_passive_list' -and ($r.op -notin @('replace_passive_list','scale_amount') -or $r.target -ne 'target' -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.interval_turns -or $r.per_action -or $r.unique_targets -or $r.budget -ne 'none' -or $r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.cap_bp -or $r.duration)){throw 'Invalid passive list query'}
        if($r.op -eq 'replace_passive_list' -and ($r.event -ne 'before_passive_list' -or $r.argument -le 0 -or $r.flat -or -not $additiveIds.ContainsKey([string]$r.argument))){throw 'Invalid passive list replacement'}
        if($r.event -eq 'before_passive_list' -and $r.op -eq 'scale_amount' -and ($r.argument -or $r.flat -lt 0 -or $r.flat -gt 1)){throw 'Passive list flag must be boolean'}
        if($r.event -eq 'before_combo_amount' -and ($r.op -ne 'set_parameter' -or $r.argument -or $r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.cap_bp -or $r.flat -lt 0 -or $r.flat -gt 1000000 -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.interval_turns -or $r.per_action -or $r.unique_targets -or $r.budget -ne 'none')){throw 'Invalid combo coefficient query'}
        if($r.event -eq 'before_self_damage' -and ($r.op -ne 'scale_amount' -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.interval_turns -or $r.per_action -or $r.unique_targets -or $r.budget -ne 'none')){throw 'Invalid self damage limit'}
        if($r.event -eq 'before_sacrifice_damage' -and ($r.op -ne 'set_parameter' -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.per_action -or $r.interval_turns -or $r.unique_targets -or $r.budget -ne 'none' -or $r.duration -or $r.cap_bp -or $r.growth_bp -or ($r.argument -eq 2 -and ($r.basis -ne 'one' -or $r.ratio_bp -or $r.flat -lt 0 -or $r.flat -gt 1000000)))){throw 'Invalid sacrifice damage query'}
        if($r.op -eq 'replace_buff' -and ($r.event -notin @('before_buff','before_buff_attempt') -or $r.target -ne 'target' -or $r.argument -le 0 -or $r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.flat -or $r.cap_bp -or $r.probability_bp -ne 10000 -or $r.budget -ne 'none')){throw 'Invalid attempted buff replacement'}
        if($r.event -eq 'before_passive_raw_parameters' -and ($r.op -notin @('set_parameter','add_parameter_flat','add_parameter_bonus') -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.interval_turns -or $r.per_action -or $r.unique_targets -or $r.budget -ne 'none')){throw 'Raw parameter query must be deterministic'}
        if($r.event -eq 'before_action_repeat' -and ($r.op -ne 'set_parameter' -or $r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.cap_bp -or $r.flat -lt 0 -or $r.flat -gt 1000000 -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.interval_turns -or $r.per_action -or $r.unique_targets -or $r.budget -ne 'none')){throw 'Invalid repeated action scale'}
        if($r.event -eq 'accepted_kill_action' -and ($r.op -ne 'gate' -or $r.per_turn -or $r.per_battle -or $r.interval_turns -or $r.per_action -or $r.unique_targets -or $r.budget -ne 'none')){throw 'Accepted kill action requires unlimited deterministic record'}
        if($r.event -in @('before_passive_parameters','after_passive_attribute_roll') -and ($r.op -notin @('set_parameter','scale_amount','add_parameter_flat','add_parameter_bonus') -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.interval_turns -or $r.per_action -or $r.unique_targets -or $r.budget -ne 'none')){throw 'Passive query must be a deterministic modifier'}
        if($r.event -in @('before_passive_parameters','after_passive_attribute_roll') -and $r.op -eq 'scale_amount' -and ($r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.cap_bp -or $r.flat -lt 0 -or $r.flat -gt 1)){throw 'Passive query flag must be a constant boolean'}
        if($r.event -eq 'before_kill_action' -and ($r.op -notin @('gate','chance_gate','set_parameter') -or ($r.op -ne 'chance_gate' -and $r.probability_bp -ne 10000) -or $r.unique_targets -or $r.budget -ne 'none')){throw 'Invalid kill action query'}
        if($r.event -eq 'before_kill_action' -and $r.op -eq 'set_parameter' -and ($r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.cap_bp -or $r.flat -lt 0 -or $r.flat -gt $(if($r.argument -eq 0){2}else{1000000}))){throw 'Invalid kill action parameter'}
        if($r.event -in @('finalize_heal','before_passive_revive','before_skill_usefulness','before_revive_eligibility','before_shield_passive')) {
            $allowed=if($r.event -in @('before_skill_usefulness','before_revive_eligibility','before_shield_passive')){$r.op -eq 'set_parameter'}elseif($r.event -eq 'before_passive_revive'){$r.op -eq 'scale_amount'}else{$r.op -in @('scale_amount','set_parameter')}
            if(-not $allowed -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.interval_turns -or $r.per_action -or $r.unique_targets -or $r.budget -ne 'none'){throw 'Healing/usefulness query must be deterministic'}
            if($r.op -eq 'set_parameter' -and ($r.basis -ne 'one' -or $r.ratio_bp -or $r.growth_bp -or $r.cap_bp -or $r.flat -lt 0 -or $r.flat -gt 1)){throw 'Query flag must be a constant boolean'}
        }
        if($r.op -eq 'multiply_amount' -and ($r.event -notin @('before_thorns_amount','before_hp_restore','before_passive_heal','before_passive_value','before_speed','before_share_damage','before_stat','before_direct_amount') -or $r.target -ne 'target')){throw 'Invalid sequential multiplier'}
        if($r.event -in @('before_thorns_roll','before_thorns_amount')) {
            $expected=if($r.event -eq 'before_thorns_roll'){'add_amount_bonus'}else{'multiply_amount'}
            if($r.op -ne $expected -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.interval_turns -or $r.per_action -or $r.unique_targets -or $r.budget -ne 'none' -or $r.duration){throw 'Thorns query must be deterministic'}
        }
        if($r.event -eq 'before_hp_restore' -and ($r.op -ne 'multiply_amount' -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.interval_turns -or $r.per_action -or $r.unique_targets -or $r.budget -ne 'none' -or $r.duration)){throw 'HP restoration query must be deterministic'}
        if($r.event -eq 'before_direct_amount' -and ($r.op -ne 'multiply_amount' -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.interval_turns -or $r.per_action -or $r.unique_targets -or $r.budget -ne 'none')){throw 'Direct amount query must be deterministic'}
        if($r.event -eq 'before_stat' -and ($r.op -ne 'multiply_amount' -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.interval_turns -or $r.per_action -or $r.unique_targets -or $r.budget -ne 'none')){throw 'Attribute query must be deterministic'}
        if($r.event -eq 'before_share_damage' -and ($r.op -notin @('multiply_amount','add_amount_bonus') -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.interval_turns -or $r.per_action -or $r.unique_targets -or $r.budget -ne 'none')){throw 'Share query must be a deterministic stat modifier'}
        if($r.event -eq 'before_speed' -and ($r.op -ne 'multiply_amount' -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.interval_turns -or $r.per_action -or $r.unique_targets -or $r.budget -ne 'none')){throw 'Speed query must be a deterministic stat modifier'}
        if($r.event -eq 'before_action_order' -and ($r.op -ne 'add_amount_bonus' -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.interval_turns -or $r.per_action -or $r.unique_targets -or $r.budget -ne 'none')){throw 'Order query must be a deterministic modifier'}
        if($r.event -eq 'before_tactic_cost' -and ($r.op -ne 'add_amount_bonus' -or $r.probability_bp -ne 10000 -or $r.per_turn -or $r.per_battle -or $r.interval_turns -or $r.per_action -or $r.unique_targets -or $r.budget -ne 'none')){throw 'Cost query must be a deterministic modifier'}
        if($r.stack_key -lt 0 -or $r.stack_policy -notin @('stack','replace_source','highest') -or (($r.stack_key -gt 0) -ne ($r.stack_policy -ne 'stack')) -or ($r.stack_key -gt 0 -and $r.op -ne 'buff')){throw 'Invalid buff stacking policy'}
        if($r.presentation_skill -lt -1 -or $r.presentation_skill -gt 65535 -or ($r.presentation_skill -gt 0 -and -not $skillIds.ContainsKey([string]$r.presentation_skill) -and -not $gearOrigins.ContainsKey("$($r.group_id):$($r.presentation_skill)"))){throw 'Invalid presentation skill reference'}
        if($r.stack_key -gt 0){
            $key=[string]$r.stack_key; $signature="$($r.argument):$($r.stack_policy)"
            if($stackContracts.ContainsKey($key) -and $stackContracts[$key] -ne $signature){throw 'Conflicting buff stacking contract'}
            $stackContracts[$key]=$signature
        }
        if($r.op -eq 'add_parameter_bonus' -and $r.argument -gt $(if($r.event -eq 'before_passive_raw_parameters'){4}else{3})){throw 'Invalid modifier parameter index'}
        Assert-Conditions $r.conditions $fields
        Describe $r
        $groups[[string]$r.group_id]=$true
    }
    foreach($reset in @($Tables.combat_effect|Where-Object op -eq 'reset_counter')) {
        $record=Get-SourceCounterRecord ([long]$reset.argument)
        if($record.per_turn -or $record.per_battle -or $record.interval_turns -or $record.per_action -or $record.unique_targets -or $record.budget -ne 'none'){throw 'State reset requires unlimited source gate'}
    }
    foreach($affix in $Tables.equipment_affix) {
        $effects=@($Tables.combat_effect|Where-Object affix_id -eq $affix.id)
        $periodicEffects=@($Tables.combat_periodic|Where-Object bonus_affix -eq $affix.id)
        if(-not $effects.Count -and -not $periodicEffects.Count){continue}
        $affix['combat_descriptions']=@(foreach($tier in 0..2){
            $values=@{affix_value1=$affix.value1[$tier];affix_value2=$affix.value2[$tier];affix_duration=$affix.duration}
            $descriptions=@(foreach($e in $effects){$copy=[ordered]@{};foreach($k in $e.Keys){$copy[$k]=$e[$k]};Describe $copy $null $values;$copy.description})
            $descriptions+=@(foreach($periodicGroup in ($periodicEffects|Group-Object -Property {$_['bonus_cap_bp']})){
                $names=@($periodicGroup.Group|ForEach-Object {$buffNames[[string]$_.buff_id]}) -join '、'
                $bonus=([decimal]$affix.value1[$tier]/100).ToString([Globalization.CultureInfo]::InvariantCulture)
                $cap=([decimal]$periodicGroup.Group[0]['bonus_cap_bp']/100).ToString([Globalization.CultureInfo]::InvariantCulture)
                "${names}的周期伤害增加${bonus}%，与其他周期加伤共享${cap}%上限"
            })
            ($descriptions|Select-Object -Unique)-join '；'
        })
    }
    $artifactIds=@{}; $suitIds=@{}
    foreach($r in @(Read-UnityVisualExcelRows (Join-Path $Root 'unitydata/excel/fabao.xlsx'))){if($r.equip -eq '1' -and [string]$r.id -match '^\d+$'){$artifactIds[[string]$r.id]=[int]$r.quality}}
    foreach($r in @(Read-UnityVisualExcelRows (Join-Path $Root 'unitydata/excel/suit.xlsx'))){if([string]$r.id -match '^\d+$'){$suitIds[[string]$r.id]=$true}}
    foreach($r in $Tables.suit){
        if($r.suit.Count -ne 3){throw 'Invalid suit piece tiers'}
        foreach($tier in $r.suit){
            if($tier -isnot [array]){throw 'Invalid suit tier'}
            foreach($attr in $tier){
                if($attr.Count -ne 3 -or $attr[0] -ne 1 -or -not (($attr[1] -ge 1 -and $attr[1] -le 33) -or ($attr[1] -ge 50 -and $attr[1] -le 54)) -or @($attr|Where-Object {[string]$_ -notmatch '^-?\d+$'}).Count){throw 'Invalid suit attribute tuple/protocol'}
            }
        }
    }
    $seenArtifacts=@{}; $setKeys=@{}; $slotPriorities=@{}; $artifactKeys=@{}; $gearGroupOwners=@{}
    foreach($r in $Tables.combat_artifact){
        if(-not $artifactIds.ContainsKey([string]$r.id) -or $r.quality -ne $artifactIds[[string]$r.id] -or $r.family -lt 1 -or $r.selection_rank -lt 0 -or [string]::IsNullOrWhiteSpace($r.exclusive_group)){throw "Invalid artifact binding/quality: $($r.id)"}
        $seenArtifacts[[string]$r.id]=$true
        $key="$($r.family):$($r.quality)"; if($artifactKeys.ContainsKey($key)){throw 'Duplicate artifact family/quality'};$artifactKeys[$key]=$true
        if($r.effect_group -gt 0){$key=[string]$r.effect_group;$owner='artifact:'+$r.exclusive_group;if($gearGroupOwners.ContainsKey($key) -and $gearGroupOwners[$key] -ne $owner){throw 'Conflicting equipment effect group'};$gearGroupOwners[$key]=$owner}
    }
    if($seenArtifacts.Count -ne $artifactIds.Count){throw 'Missing formal artifact combat binding'}
    foreach($r in $Tables.combat_set){
        $key="$($r.suit_id):$($r.pieces)"
        if(-not $suitIds.ContainsKey([string]$r.suit_id) -or $r.pieces -lt 1 -or $r.pieces -gt 4 -or $setKeys.ContainsKey($key)){throw "Invalid set binding/threshold: $key"}
        $setKeys[$key]=$true
        if($r.effect_group -gt 0){$key=[string]$r.effect_group;if($gearGroupOwners.ContainsKey($key)){throw 'Conflicting equipment effect group'};$gearGroupOwners[$key]='set:'+$r.suit_id}
    }
    foreach($r in @($Tables.combat_artifact)+@($Tables.combat_set)){
        if($r.value -lt 0 -or $r.value -gt 1000000 -or $r.enabled -notin @(0,1) -or $r.effect_group -lt 0 -or ($r.effect_group -gt 0 -and -not $groups.ContainsKey([string]$r.effect_group)) -or ($r.enabled -eq 1 -and ($r.status -ne 'complete' -or $r.effect_group -eq 0))){throw "Invalid equipment effect/status: $($r.id)"}
        $parts=@(foreach($e in $Tables.combat_effect | Where-Object group_id -eq $r.effect_group){$copy=[ordered]@{};foreach($k in $e.Keys){$copy[$k]=$e[$k]};Describe $copy $r.value;$copy.description})
        $r['description']=if($parts.Count){($parts|Select-Object -Unique)-join '；'}elseif($r.status -eq 'base_attributes'){'基础属性由同工作簿 suit 表结算'}else{'机制待迁移，未启用'}
    }
    foreach($r in $Tables.combat_loadout_slot){
        if($r.id -lt 1 -or $r.id -gt 6 -or $r.kind -notin @('equipment','artifact') -or $r.priority -lt 1 -or $slotPriorities.ContainsKey([string]$r.priority)){throw 'Invalid/ambiguous loadout slot policy'}
        $slotPriorities[[string]$r.priority]=$true
        if(($r.id -le 4) -ne ($r.kind -eq 'equipment')){throw 'Loadout kind disagrees with slot protocol'}
    }
    if($Tables.combat_loadout_slot.Count -ne 6){throw 'Missing loadout slot policy'}
    $counterContracts=@{}
    $amountContracts=@{}
    foreach($e in $Tables.combat_effect){
        $earlier=if($e.ratio_source -eq 'event_bonus' -or $e.basis -eq 'event_hp_loss' -or $e.cap_basis -eq 'event_hp_loss'){@($Tables.combat_effect|Where-Object {$_.group_id -eq $e.group_id -and $_.event -eq $e.event -and ($_.priority -lt $e.priority -or ($_.priority -eq $e.priority -and $_.id -lt $e.id))})}else{@()}
        if($e.ratio_source -eq 'event_bonus' -and -not @($earlier|Where-Object op -eq 'add_event_bonus').Count){throw 'Missing prior event coefficient producer'}
        if(($e.basis -eq 'event_hp_loss' -or $e.cap_basis -eq 'event_hp_loss') -and -not @($earlier|Where-Object op -eq 'passive_damage').Count){throw 'Missing prior HP loss producer'}
        if($e.affix_id -and $gearGroupOwners.ContainsKey([string]$e.group_id)){throw 'Affix cannot alias equipment group'}
        foreach($field in @($e.basis,$e.cap_basis,$e.growth_basis,$e.basis_cap)+@($e.conditions|ForEach-Object {$_.field;if($_.Contains('value_field')){$_.value_field}})){
            if($field -match '^(source_)?mark_(value|source|present)_([1-9][0-9]*)$'){$markId=[long]$Matches[3];$markRecord=@($Tables.combat_effect|Where-Object id -eq $markId)[0];if(-not $markRecord -or $markRecord.op -ne 'mark' -or $markRecord.group_id -ne $e.group_id){throw 'Invalid timed mark reference'}}
            if($field -match '^(target_)?state_value_([1-9][0-9]*)$'){
                $stateId=[long]$Matches[2];$scope=if($Matches[1]){'target'}else{'source'};$stateRecord=@($Tables.combat_effect|Where-Object id -eq $stateId)[0]
                if(-not $stateRecord -or $stateRecord.op -notin @('state_set','state_add') -or $stateRecord.group_id -ne $e.group_id -or $stateRecord.counter_scope -ne $scope){throw 'Invalid numeric state reference'}
            }
            if($field -eq 'source_is_group_hp_leader' -and -not $gearGroupOwners.ContainsKey([string]$e.group_id)){throw 'Equipment leader fact requires equipment group'}
        }
        if($e.op -in @('state_set','state_add') -and $e.counter_key){$stateRecord=@($Tables.combat_effect|Where-Object id -eq $e.counter_key)[0];if(-not $stateRecord -or $stateRecord.op -notin @('state_set','state_add') -or $stateRecord.group_id -ne $e.group_id -or $stateRecord.counter_scope -ne $e.counter_scope){throw 'Invalid numeric state alias'}}
        if($e.binding_scope -in @('source_mark','target_mark') -and -not @($Tables.combat_effect|Where-Object {$_.group_id -eq $e.group_id -and $_.op -eq 'mark'}).Count){throw 'Mark binding has no producer'}
        if($e.op -eq 'mark' -and $e.counter_key){$markRecord=@($Tables.combat_effect|Where-Object id -eq $e.counter_key)[0];if(-not $markRecord -or $markRecord.op -ne 'mark' -or $markRecord.group_id -ne $e.group_id){throw 'Invalid timed mark alias'}}
        if($e.op -eq 'combine_remaining') {
            $operands=if($e.basis -eq 'affix_value1'){@(($Tables.equipment_affix|Where-Object id -eq $e.affix_id).value1)}else{@(@($Tables.combat_artifact)+@($Tables.combat_set)|Where-Object effect_group -eq $e.group_id|ForEach-Object {$_.value})}
            if(@($operands|Where-Object {$_ -lt 0 -or [decimal]$_*$e.ratio_bp/10000 -gt 10000}).Count){throw 'Remaining fraction outside 0..10000'}
        }
        if(($e.ratio_source -eq 'gear_value' -or $e.cap_ratio_source -eq 'gear_value' -or $e.basis -eq 'gear_value' -or $e.cap_basis -eq 'gear_value') -and -not $gearGroupOwners.ContainsKey([string]$e.group_id)){throw 'Gear value requires equipment group'}
        if($e.target -eq 'highest_gear_ally' -and -not $gearGroupOwners.ContainsKey([string]$e.group_id)){throw 'Equipment selector requires equipment group'}
        $key=[string]$(if($e.counter_key){$e.counter_key}else{$e.id});$contract="$($e.counter_scope):$($e.per_turn):$($e.per_battle):$($e.interval_turns):$($e.per_action):$($e.unique_targets)"
        if($counterContracts.ContainsKey($key) -and $counterContracts[$key] -ne $contract){throw 'Incompatible shared counter contract'}
        $counterContracts[$key]=$contract
        $amountContract=if($e.amount_budget -eq 'none'){'none'}else{"$($e.amount_budget):$($e.group_id):$($e.cap_bp):$($e.cap_basis):$($e.cap_ratio_source)"}
        if($amountContracts.ContainsKey($key) -and $amountContracts[$key] -ne $amountContract){throw 'Incompatible shared amount budget contract'}
        $amountContracts[$key]=$amountContract
    }
    $bindings=@{}
    foreach($r in $Tables.combat_binding) {
        $key='{0}:{1}' -f $r.hero_id,$r.branch
        if(-not $heroIds.ContainsKey([string]$r.hero_id) -or $r.branch -notin @(1,2) -or $r.enabled -notin @(0,1) -or $bindings.ContainsKey($key) -or -not $r.groups.Count -or ($r.groups | Select-Object -Unique).Count -ne $r.groups.Count) { throw "Invalid combat binding: $key" }
        foreach($group in $r.groups) { if(-not $groups.ContainsKey([string]$group)) { throw "Missing combat effect group: $group" } }
        foreach($group in $r.groups){if($gearGroupOwners.ContainsKey([string]$group) -or $affixGroups.ContainsKey([string]$group)){throw 'Hero binding cannot alias an equipment group'}}
        if($r.enabled -eq 1 -and $r.status -ne 'complete') { throw "Incomplete branch cannot be enabled: $key" }
        $bindings[$key]=$true
    }
    $priorities=@{}
    $targetIds=@{};$targetPriorities=@{}
    foreach($r in $Tables.combat_target_policy) {
        if($r.id -lt 1 -or $r.id -gt [int]::MaxValue -or $targetIds.ContainsKey([string]$r.id)){throw 'Duplicate/invalid target policy id'};$targetIds[[string]$r.id]=$true
        if($r.strategy_id -lt 1 -or $r.strategy_id -gt 5 -or $r.priority -lt 0 -or $r.priority -gt [int]::MaxValue -or $r.enabled -notin @(0,1) -or $r.side -cnotin @('ally','enemy') -or $r.role -cnotin @('any','regular','tactic','other') -or $r.order -cnotin @('lowest_hp','unshielded_lowest_hp','highest_attack','fewest_owned_dots','most_owned_dots') -or $r.tie_break -cnotin @('position_asc','position_desc')){throw 'Invalid target policy vocabulary/range'}
        $key="$($r.strategy_id):$($r.side):$($r.role):$($r.priority)";if($targetPriorities.ContainsKey($key)){throw 'Conflicting target policy priority'};$targetPriorities[$key]=$true
        $seenBuffs=@{};foreach($id in $r.count_buff_ids){if(-not $buffIds.ContainsKey([string]$id) -or $seenBuffs.ContainsKey([string]$id)){throw 'Invalid target count buff'};$seenBuffs[[string]$id]=$true}
        if(($r.order -in @('fewest_owned_dots','most_owned_dots')) -ne ([bool]$r.count_buff_ids.Count)){throw 'Invalid target count buff contract'}
        Describe $r
    }
    foreach($r in $Tables.combat_strategy) {
        $key='{0}:{1}' -f $r.strategy_id,$r.priority
        if($r.strategy_id -notin 1..5 -or $r.priority -lt 0 -or $r.reserve -lt 0 -or $r.reserve -gt 100 -or $r.emergency -notin @(0,1) -or $r.role -notin @('tactic','regular','normal') -or $priorities.ContainsKey($key)) { throw "Invalid combat strategy: $key" }
        Assert-Conditions $r.conditions $contextFields.strategy
        Describe $r
        $priorities[$key]=$true
    }
    foreach($id in 1..5) {
        $last=$Tables.combat_strategy | Where-Object strategy_id -eq $id | Sort-Object priority | Select-Object -Last 1
        if(-not $last -or $last.role -ne 'normal' -or $last.conditions.Count) { throw "Strategy $id requires unconditional normal fallback" }
    }
    $periodicBuffs=@{}
    foreach($r in $Tables.combat_periodic) {
        if($r.zero_action_parameter -lt -1 -or $r.zero_action_parameter -gt 3){throw 'Invalid periodic zero action parameter'}
        if($r.aggregation -cnotin @('per_source','state_sum')){throw 'Invalid periodic aggregation'}
        if($r.bonus_affix -lt 0 -or $r.bonus_cap_bp -lt 0 -or $r.bonus_cap_bp -gt 10000 -or ($r.bonus_affix -gt 0 -and ($r.bonus_affix -notin @($Tables.equipment_affix.id) -or $r.bonus_cap_bp -eq 0))){throw 'Invalid periodic affix/cap reference'}
        if(-not $buffIds.ContainsKey([string]$r.buff_id) -or $periodicBuffs.ContainsKey([string]$r.buff_id) -or ($r.bonus_buff -ne 0 -and -not $buffIds.ContainsKey([string]$r.bonus_buff))) { throw "Invalid periodic buff reference: $($r.id)" }
        if($r.event -notin @('before_action','after_heal') -or $r.outcome -notin @('damage','heal') -or $r.formula -notin @('sum','percent','percent_cap') -or $r.basis -notin @('one','target_hp','target_max_hp','input') -or ($r.basis -eq 'input' -and $r.event -ne 'after_heal')) { throw "Invalid periodic formula: $($r.id)" }
        if($r.param_a -lt 0 -or $r.param_a -gt 3 -or $r.param_b -lt -1 -or $r.param_b -gt 3 -or $r.cap_param -lt -1 -or $r.cap_param -gt 3 -or $r.stack_group -lt 0 -or $r.turn_budget -notin @(0,1) -or $r.bonus_bp -lt 0 -or $r.bonus_bp -gt 10000 -or ($r.formula -eq 'percent_cap' -and $r.cap_param -lt 0)) { throw "Invalid periodic range: $($r.id)" }
        if(($r.formula -eq 'sum' -and $r.basis -ne 'one') -or ($r.formula -ne 'sum' -and $r.param_b -ne -1) -or ($r.formula -ne 'percent_cap' -and $r.cap_param -ne -1) -or ($r.outcome -eq 'heal' -and ($r.turn_budget -ne 0 -or $r.stack_group -ne 0))) { throw "Incompatible periodic policy: $($r.id)" }
        Describe $r
        $periodicBuffs[[string]$r.buff_id]=$true
    }
    $controlBuffs=@{}
    foreach($r in $Tables.combat_control) {
        if($r.refresh_same_origin -notin @(0,1)) { throw "Invalid control refresh: $($r.id)" }
        if(-not $buffIds.ContainsKey([string]$r.buff_id) -or $controlBuffs.ContainsKey([string]$r.buff_id) -or $r.diminishing -notin @(0,1) -or $r.boss_mode -notin @('normal','ignore','replace') -or $r.replacement_value -lt 0 -or $r.replacement_value -gt 1000000 -or $r.replacement_duration -lt 0 -or $r.replacement_duration -gt 255){throw "Invalid control policy: $($r.id)"}
        if(($r.replacement_buff -ne 0 -and -not $buffIds.ContainsKey([string]$r.replacement_buff)) -or ($r.boss_mode -eq 'replace' -and ($r.replacement_buff -eq 0 -or $r.replacement_buff -eq $r.buff_id -or $r.replacement_duration -eq 0))){throw "Invalid boss control replacement: $($r.id)"}
        $controlBuffs[[string]$r.buff_id]=$true
    }
    $required=@('rage_max','shield_cap_bp','dot_max_stacks','dot_max_duration','secondary_depth_max','revive_per_target','extra_attack_per_turn','strategy_injured_hp_bp','shield_refresh_same_source','dot_poison_shared_budget','dot_turn_attack_bp','revive_per_source_target','control_reset_gap','control_immunity_threshold','control_reduce_threshold','control_duration_bp','control_min_duration','control_immunity_turns','boss_control_per_turn','revived_extra_block_turns','direct_multiplier_min_bp','direct_multiplier_max_bp')
    $required+=@('rage_extra_actor_turn','rage_extra_team_turn','rage_opening_team','rage_normal_hit','rage_regular_success','rage_damage_taken','rage_damage_events_turn','rage_kill','rage_first_death','rage_tactic_min_cost')
    $required+='shield_pierce_success_bp'
    $required+=@('guard_cap_bp','guard_multiplier_min_bp','ignore_defense_cap_bp')
    $required+=@('direct_hit_min_bp','direct_hit_max_bp')
    $required+=@('active_heal_bonus_min_bp','active_heal_bonus_max_bp','active_antiheal_enabled','revive_antiheal_enabled')
    $required+='overheal_shield_conversion_cap_bp'
    $required+=@('critical_chance_cap_bp','critical_multiplier_min_bp','critical_multiplier_max_bp')
    $required+=@('vulnerability_multiplier_max_bp','revived_action_block_turns','shared_link_target_select','shared_link_target_count','action_attribute_stack_cap','boss_attack_weaken_cap_bp','boss_defense_weaken_cap_bp','defense_weaken_cap_bp')
    $required+=@('buff_tick_same_action_skip','thorns_requires_hp_loss','thorns_cap_bp','thorns_per_turn','vulnerability_keep_highest','buff_refresh_same_origin','cooldown_tick_action_begin','rage_from_shared_damage')
    $rules=@{}
    foreach($r in $Tables.combat_rule) {
        $flag=$r.key -in @('shield_refresh_same_source','dot_poison_shared_budget','active_antiheal_enabled','revive_antiheal_enabled','buff_tick_same_action_skip','thorns_requires_hp_loss','vulnerability_keep_highest','buff_refresh_same_origin','cooldown_tick_action_begin','rage_from_shared_damage')
        $minimum=if($r.key -in @('active_heal_bonus_min_bp','active_heal_bonus_max_bp')){-10000}elseif($flag -or $r.key -in @('revived_extra_block_turns','direct_multiplier_min_bp','shield_pierce_success_bp','direct_hit_min_bp','direct_hit_max_bp')){0}else{1}; $maximum=if($flag){1}elseif($r.key -eq 'secondary_depth_max'){8}elseif($r.key -in @('dot_max_duration','control_min_duration')){255}elseif($r.key -in @('dot_turn_attack_bp','direct_multiplier_min_bp','direct_multiplier_max_bp')){1000000}else{10000}
        if($r.key -in @('revived_action_block_turns','overheal_shield_conversion_cap_bp','thorns_cap_bp','thorns_per_turn','boss_attack_weaken_cap_bp','boss_defense_weaken_cap_bp','defense_weaken_cap_bp')){$minimum=0}
        if($r.key -eq 'shared_link_target_select'){$maximum=19}
        if($r.key -eq 'shared_link_target_count'){$maximum=9}
        if($r.key -eq 'vulnerability_multiplier_max_bp'){$minimum=10000;$maximum=1000000}
        if($r.key -eq 'critical_chance_cap_bp'){$minimum=0;$maximum=10000}
        if($r.key -in @('critical_multiplier_min_bp','critical_multiplier_max_bp')){$minimum=10000;$maximum=1000000}
        if($r.key -notin $required -or $rules.ContainsKey($r.key) -or $r.value -lt $minimum -or $r.value -gt $maximum -or $r.scope -ne 'all_units') { throw "Invalid combat shared rule: $($r.key)" }
        $rules[$r.key]=$true
    }
    foreach($key in $required) { if(-not $rules.ContainsKey($key)) { throw "Missing combat rule: $key" } }
    $reduce=($Tables.combat_rule|Where-Object key -eq 'control_reduce_threshold').value
    $immune=($Tables.combat_rule|Where-Object key -eq 'control_immunity_threshold').value
    if($reduce -ge $immune){throw 'Control reduction must precede immunity'}
    if(($Tables.combat_rule|Where-Object key -eq 'direct_multiplier_min_bp').value -gt ($Tables.combat_rule|Where-Object key -eq 'direct_multiplier_max_bp').value){throw 'Inverted direct multiplier range'}
    if(($Tables.combat_rule|Where-Object key -eq 'direct_hit_min_bp').value -gt ($Tables.combat_rule|Where-Object key -eq 'direct_hit_max_bp').value){throw 'Inverted direct hit range'}
    if(($Tables.combat_rule|Where-Object key -eq 'active_heal_bonus_min_bp').value -gt ($Tables.combat_rule|Where-Object key -eq 'active_heal_bonus_max_bp').value){throw 'Inverted active healing range'}
    if(($Tables.combat_rule|Where-Object key -eq 'critical_multiplier_min_bp').value -gt ($Tables.combat_rule|Where-Object key -eq 'critical_multiplier_max_bp').value){throw 'Inverted critical multiplier range'}
    if(($Tables.combat_rule|Where-Object key -eq 'rage_tactic_min_cost').value -gt ($Tables.combat_rule|Where-Object key -eq 'rage_max').value){throw 'Tactic minimum exceeds rage cap'}
}
