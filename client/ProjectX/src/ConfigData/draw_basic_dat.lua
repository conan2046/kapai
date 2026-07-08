draw_basic_dat = {
	{
		id = 1,
		name = "基础招募",
		open_level = 1,
		type = 1,
		must_be = 2,
		must_get = {{60014,0,10}},
		need_item_id = 1000,
		need_item_num = 1,
		must_be_out_times = 10,
		free_times = 3,
		free_interval = 300
	},
	{
		id = 2,
		name = "高级招募",
		open_level = 1,
		type = 3,
		must_be = 4,
		must_get = {{60014,0,100}},
		need_item_id = 1001,
		need_item_num = 1,
		must_be_out_times = 10,
		free_times = 1,
		free_interval = 0
	},
	{
		id = 3,
		name = "友情招募",
		open_level = 5,
		type = 5,
		must_be = 6,
		must_get = {{60014,0,50}},
		need_item_id = 1002,
		need_item_num = 10,
		must_be_out_times = 6,
		free_times = 0,
		free_interval = 0
	}
}

return draw_basic_dat
