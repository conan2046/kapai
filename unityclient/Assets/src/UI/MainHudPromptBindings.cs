using System;
using UnityEngine;

namespace ProjectX.UI
{
    [DisallowMultipleComponent]
    public sealed class MainHudPromptBindings : MonoBehaviour
    {
        [SerializeField] private GameObject gameplay;
        [SerializeField] private GameObject equipment;
        [SerializeField] private GameObject formation;
        [SerializeField] private GameObject recruitment;
        [SerializeField] private GameObject shop;
        [SerializeField] private GameObject mail;
        [SerializeField] private GameObject dungeon;

        public GameObject[] StablePrompts => new[]
        {
            Require(gameplay, nameof(gameplay)),
            Require(equipment, nameof(equipment)),
            Require(formation, nameof(formation)),
            Require(recruitment, nameof(recruitment)),
            Require(shop, nameof(shop)),
            Require(dungeon, nameof(dungeon))
        };

        public GameObject ResolveRedDot(int redType)
        {
            return redType switch
            {
                31 => Require(mail, nameof(mail)),
                41 or 51 or 101 or 103 => Require(gameplay, nameof(gameplay)),
                61 or 63 or 64 => Require(dungeon, nameof(dungeon)),
                71 or 72 => Require(shop, nameof(shop)),
                _ => null
            };
        }

        private static GameObject Require(GameObject target, string name)
        {
            return target != null ? target : throw new InvalidOperationException(
                $"Main HUD prompt reference is missing: {name}.");
        }
    }
}
