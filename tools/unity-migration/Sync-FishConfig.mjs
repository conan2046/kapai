// Historical Fish G0 write-back is retired; this entry performs no data writes.
throw new Error(
  "Sync-FishConfig is retired. --restore-clean-head-order is unsupported. " +
  "Maintain Unity client data under unitydata/export/client/source/Configs and export with " +
  "unitydata/tools/Export-UnityClientData.ps1. Unity server Fish tables currently retain their " +
  "unityserver/config/json baseline; the historical G0 exporter must not overwrite it."
);
