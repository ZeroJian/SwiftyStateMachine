# SwiftyStateMachine
使用 Swift 编写的状态机



````swift
var stateMachine = StateMachine.init(0)

// 注册监听
stateMachine
		.listen([-1, -2, -3, -4, -5, -21, -30],
				from: [2,3],
				to: -1)
		.listen(1,
				from: 0,
				to: 1)
		.listen(2,
				from: 5,
				to: 6,
                action: { s, e in
               	})

// 所有状态改变的回调
stateMachine.transitionHandle { [weak self](t) in
   	print(action transition)
}

// 所有触发事件回调(状态可能未改变)
stateMachine.triggerHandle { [weak self](statu) in
	print(trigger statu)
}

// 可触发 triggerHadnle 的规则
stateMachine.triggerHandleRule(filterRule: { [weak self](new, current) -> Bool in
     return i > t
})

// 触发器
stateMachine.trigger(statu)
````





