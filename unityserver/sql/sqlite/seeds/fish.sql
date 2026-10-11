-- BEGIN GENERATED UNITY FISH SEED
INSERT INTO fish_settings (id,gold_cost,cycle_min_seconds,cycle_max_seconds,basket_capacity,fish_stack_limit,auto_continue) VALUES
(1,100,10,20,9999,999,1)
ON CONFLICT(id) DO UPDATE SET gold_cost=excluded.gold_cost,cycle_min_seconds=excluded.cycle_min_seconds,cycle_max_seconds=excluded.cycle_max_seconds,basket_capacity=excluded.basket_capacity,fish_stack_limit=excluded.fish_stack_limit,auto_continue=excluded.auto_continue;
INSERT INTO fish_position (id,scene_id,map_id,x,y,dir,flip,fishing_shape_id) VALUES
(1,54,33,1086,619,2,1,2000)
ON CONFLICT(id) DO UPDATE SET scene_id=excluded.scene_id,map_id=excluded.map_id,x=excluded.x,y=excluded.y,dir=excluded.dir,flip=excluded.flip,fishing_shape_id=excluded.fishing_shape_id;
DELETE FROM fish_reward;
INSERT INTO fish_reward (id,item_id,weight,enabled,sort,use_reward_id) VALUES
(1,580,50,1,1,0),
(2,581,35,1,2,0),
(3,582,15,1,3,0),
(4,10580,80,1,4,0),
(5,10581,65,1,5,0),
(6,10582,40,1,6,0),
(7,10583,25,1,7,0),
(8,10584,15,1,8,0),
(9,10585,5,1,9,0),
(10,10586,1,1,10,0)
ON CONFLICT(id) DO UPDATE SET item_id=excluded.item_id,weight=excluded.weight,enabled=excluded.enabled,sort=excluded.sort,use_reward_id=excluded.use_reward_id;
-- END GENERATED UNITY FISH SEED
