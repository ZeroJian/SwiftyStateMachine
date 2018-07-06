//
//  StateMachine.swift
//  StatusMachine
//
//  Created by ZeroJianMBP on 2018/5/18.
//  Copyright © 2018年 ZeroJian. All rights reserved.
//

import Foundation

//protocol StateType: Hashable {}

//protocol EventType: Hashable {}

/// 状态机结构体
public struct Transition<S: Hashable, E: Hashable> {
	
	/// 触发事件(状态)
	let event: E
	/// 来自(当前)状态
	let fromState: S
	/// 切换至状态
	let toState: S
	
	public init(event: E, fromState: S, toState: S) {
		self.event = event
		self.fromState = fromState
		self.toState = toState
	}
}

extension Transition: CustomStringConvertible {
	
	public var description: String {
		return "触发事件(状态): \(event), 来自(当前)状态: \(fromState), 切换至状态: \(toState)"
	}
}

/// 状态机
open class StateMachine<S: Hashable, E: Hashable> {
	
	/// 状态机操作结构体
	public struct Operation<S: Hashable, E: Hashable> {
		let transition: Transition<S, E>
		let triggerAction: (Transition<S, E>) -> Void
	}
	
	/// 当前状态
	public private(set) var currentState: S
	
	/// 前一个状态
	public private(set) var lastState: S?
	
	
	/// 初始化状态
	public init(_ currentState: S) {
		self.currentState = currentState
	}
	
	deinit {
		print("********* 销毁了 *********")
	}
	
	/// 保存所有状态机事件字典
	public var routes = [S: [E: Operation<S, E>]]()
	
	/// 每次状态迁移时触发
	public var transitionAction: ((Transition<S, E>) -> Void)?
	
	/// filterAction 触发规则, 默认 true
	fileprivate var filterRule: ((E, S) -> Bool) = { (_, _) in return true }
	
	/// 触发事件时, 满足 filterRule 规则触发, 可捕获包括未触发状态迁移的触发事件
	fileprivate var filterAction: ((E) -> Void)?
}

extension StateMachine {
	
	/// 监听事件([多个事件] 和 [多个触发状态])
	@discardableResult
	open func listen(_ event: [E], from fromStates:[S], to toState: S, action: ((Transition<S, E>) -> Void)? = nil) -> Self {
		event.forEach {
			listen($0, from: fromStates, to: toState, action: action)
		}
		return self
	}
	
	
	/// 监听事件(单个事件 和 [多个触发状态])
	@discardableResult
	open func listen(_ event: E, from fromStates:[S], to toState: S, action: ((Transition<S, E>) -> Void)? = nil) -> Self {
		fromStates.forEach {
			listen(event, from: $0, to: toState, action: action)
		}
		return self
	}
	
	
	/// 监听事件(单个事件和触发状态)
	/// event 发生时，如果当前状态为 fromState，那么转移状态到 toState，并且执行 action 回调方法
	///
	/// - Parameters:
	///   - event: 触发事件
	///   - fromState: 可触发事件的状态(什么状态可以触发)
	///   - toState: 切换至状态(触发后切换到什么状态)
	///   - action: 触发时 closure
	@discardableResult
	open func listen(_ event: E, from fromState: S, to toState: S, action: ((Transition<S, E>) -> Void)? = nil) -> Self {
		var route = routes[fromState] ?? [:]
		let transition = Transition(event: event, fromState: fromState, toState: toState)
		
		let operation = Operation(transition: transition) { [weak self](transition) in
			print(transition)
			action?(transition)
			self?.transitionAction?(transition)
		}
		
		route[event] = operation
		routes[fromState] = route
		return self
	}
}

extension StateMachine {
	
	/// 触发器
	///
	/// - Parameter event: 事件
	/// - return: 是否触发 Trigger
	@discardableResult
	open func trigger(_ event: E) -> Bool {
		
		print("\n********** 触发状态: \(event) **********")
		
		var isTrigger: Bool = false
		
		if filterRule(event, currentState) {
			filterAction?(event)
			print("\n********** 轮询状态: \(event) ********** ")
			isTrigger = true
		}
		
		guard let route = routes[currentState]?[event] else {
			return isTrigger
		}
		
		isTrigger = true
		
		route.triggerAction(route.transition)
		lastState = currentState
		currentState = route.transition.toState
		
		return isTrigger
	}
	
}

extension StateMachine {
	
	
	/// 状态改变回调
	///
	/// - Parameter action: closure
	@discardableResult
	open func transitionHandle(_ action: @escaping (Transition<S, E>) -> Void) -> Self {
		self.transitionAction = action
		return self
	}
	
	
	/// 设置 triggerHandle 触发规则, 返回 true 触发
	/// 状态机状态未改变, 但想捕获一些事件时, 例如轮询
	///
	/// - Parameter filterRule: E: 触发的事件, S: 当前状态
	@discardableResult
	open func triggerHandleRule(filterRule: @escaping (E, S) -> Bool) -> Self {
		self.filterRule = filterRule
		return self
	}
	
	
	/// 状态机状态未改变, 但想捕获一些事件时, 例如轮询
	/// 可设置 triggerHandleRule 触发规则, 默认 filterRule 任何事件都返回 true 触发
	///
	/// - Parameter action: closure
	@discardableResult
	open func triggerHandle(action: @escaping (E) -> Void) -> Self {
		self.filterAction = action
		return self
	}
}
