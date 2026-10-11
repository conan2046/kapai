using System;
using System.Globalization;
using System.Linq;
using Newtonsoft.Json;
using ProjectX.Data;
using UnityEditor;
using UnityEngine;

namespace ProjectX.Editor
{
    public static class JingJieStateTests
    {
        public static string Run()
        {
            var state=new JingJieViewState();
            const ulong exact=9007199254740997UL;
            Func<int,ulong,ulong,JingJieSnapshot> make=(id,xp,revision)=>new JingJieSnapshot
            {
                Id=id,Experience=xp.ToString(CultureInfo.InvariantCulture),NeedExperience="6000",Revision=revision.ToString(CultureInfo.InvariantCulture),
                Power="9007199254740999",Rate=100,NextId=id==550?0:id+1,IntervalMilliseconds=5000,
                ServerMilliseconds="1700000000100",CycleMilliseconds="1700000000000"
            };
            if(!state.ApplySnapshot(make(549,exact,10)) || state.Experience!=exact)throw new Exception("64-bit realm experience was rounded.");
            state.ConsumeUpgradeEffect();
            if(state.Experience!=exact || state.Revision!=10)throw new Exception("Consuming an effect changed authoritative state.");
            if(state.ApplySnapshot(make(548,0,9)) || state.CurrentId!=549 || state.Experience!=exact)throw new Exception("Stale snapshot rolled state backwards.");
            state.ApplySnapshot(make(550,exact,11));
            if(state.NextId!=0 || !state.ConsumeUpgradeEffect() || state.Experience!=exact)throw new Exception("Maximum-stage promotion lost state.");
            var asset=AssetDatabase.LoadAssetAtPath<TextAsset>("Assets/Resources/ProjectXData/Configs/jingjie.json");
            var definitions=JsonConvert.DeserializeObject<JingJieDefinition[]>(asset.text);
            if(definitions.Length!=550 || definitions[549].RequiredExperience<=uint.MaxValue || definitions[549].Id!=550)
                throw new Exception("Formal realm definitions truncate 64-bit fields.");
            state.Clear();state.ApplySnapshot(make(1,5999,1));
            var target=definitions[1];
            if(JingJieUpgradeEligibility.Evaluate(state,target)!=JingJieUpgradeBlock.Experience)
                throw new Exception("Insufficient realm experience was accepted.");
            state.ApplySnapshot(make(1,6000,2));
            if(JingJieUpgradeEligibility.Evaluate(state,target)!=JingJieUpgradeBlock.None)
                throw new Exception("Retired level/power/material/gold conditions still block upgrades.");
            if(!state.BeginUpgrade() || state.BeginUpgrade())throw new Exception("Duplicate pending upgrade was accepted.");
            state.Clear();
            if(state.HasAuthoritativeState || state.Experience!=0 || state.Revision!=0)throw new Exception("Account switch retained realm state.");
            return "PASS: exact 64-bit state, effect consumption, stale revision, stage550, formal definitions, experience-only eligibility, pending guard and account reset.";
        }
    }
}
