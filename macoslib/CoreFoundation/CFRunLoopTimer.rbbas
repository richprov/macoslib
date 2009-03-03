#tag Class
Class CFRunLoopTimer
Inherits CFType
	#tag Event
		Function ClassID() As CFTypeID
		  return me.ClassID
		End Function
	#tag EndEvent


	#tag Method, Flags = &h21
		Private Shared Sub TimerCallback(timer as Ptr, info as Ptr)
		  dim w as WeakRef = ObjectMap.Lookup(timer, nil)
		  if w is nil then
		    //something is very wrong
		    return
		  end if
		  if not w.Value isA CFRunLoopTimer then
		    //something is very wrong
		    ObjectMap.Remove timer
		    return
		  end if
		  
		  CFRunLoopTimer(w.Value).InvokeAction
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function ClassID() As CFTypeID
		  #if targetMacOS
		    soft declare function TypeID lib CarbonLib alias "CFRunLoopTimerGetTypeID" () as UInt32
		    static id as CFTypeID = CFTypeID(TypeID)
		    return id
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(period as Double, fireTime as Date = nil)
		  //period is the time in seconds between invocations of the callback.  fireTime is the time of the first invocation.
		  
		  #if targetMacOS
		    soft declare function CFRunLoopTimerCreate lib CarbonLib (allocator as Ptr, fireDate as Double, interval as Double, flags as Uint32, order as Uint32, callout as Ptr, context as Ptr) as Ptr
		    soft declare function CFAbsoluteTimeGetCurrent lib CarbonLib () as Double
		    
		    dim fireDate as Double
		    if fireTime is nil then
		      fireDate = CFAbsoluteTimeGetCurrent + period
		    else
		      fireDate = fireTime.TotalSeconds - UnixEpoch - fireTime.GMTOffset*3600.0
		    end if
		    
		    const currentlyIgnored = 0
		    me.Constructor(CFRunLoopTimerCreate(nil, fireDate, period, currentlyIgnored, currentlyIgnored, AddressOf TimerCallback, nil), true)
		    ObjectMap.Value(me.Reference) = new WeakRef(me)
		    me.Enabled = true
		  #endif
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function ObjectMap() As Dictionary
		  static d as new Dictionary
		  return d
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Destructor()
		  #if targetMacOS
		    soft declare sub CFRunLoopTimerInvalidate lib CarbonLib (t as Ptr)
		    CFRunLoopTimerInvalidate me
		    
		    if ObjectMap.HasKey(me.Reference) then
		      ObjectMap.Remove me.Reference
		    end if
		  #endif
		End Sub
	#tag EndMethod

	#tag DelegateDeclaration, Flags = &h21
		Private Delegate Sub TimerActionDelegate()
	#tag EndDelegateDeclaration

	#tag Method, Flags = &h21
		Private Sub InvokeAction()
		  if me.Action <> nil then
		    me.Action.Invoke
		  else
		    raiseEvent Action
		  end if
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function MainRunLoop() As Ptr
		  //perhaps we should add a separate CFRunLoop class.
		  
		  #if targetMacOS
		    soft declare function CFRunLoopGetMain lib CarbonLib () as Ptr
		    
		    return CFRunLoopGetMain
		  #endif
		End Function
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event Action()
	#tag EndHook


	#tag Note, Name = Debugging
		Careful when debugging code that uses CFRunLoopTimer:
		
		CFRunLoopTimers continue to run while code execution is paused in the debugger,
		so you may not be able to single step through such timer code.
		
	#tag EndNote

	#tag Note, Name = About
		If a user opens a menu or keeps the mouse button pressed on a
		button, the Timer.Action event and code inside Thread.Run won't
		be executed.
		
		This class, however, will run in such circumstances. This makes it
		possible to keep your application able to handle other external events
		through polling.
		
		You may either add this class to a window or subclass it, with filling
		in the Action event, or create a new instance of this class and then
		assign a (delegate) method to this class's Action property.
		
	#tag EndNote


	#tag Property, Flags = &h0
		Action As TimerActionDelegate
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			#if targetMacOS
			soft declare function CFRunLoopContainsTimer lib CarbonLib (rl as Ptr, t as Ptr, mode as Ptr) as Boolean
			
			return CFRunLoopContainsTimer(MainRunLoop, me, CFBundle.CarbonFramework.DataPointerNotRetained(kCFRunLoopCommonModes).Ptr(0))
			#endif
			End Get
		#tag EndGetter
		#tag Setter
			Set
			#if targetMacOS
			
			if value = me.Enabled then
			return
			end if
			
			if value then
			soft declare sub CFRunLoopAddTimer lib CarbonLib (rl as Ptr, t as Ptr, mode as Ptr)
			
			CFRunLoopAddTimer MainRunLoop, me, CFBundle.CarbonFramework.DataPointerNotRetained(kCFRunLoopCommonModes).Ptr(0)
			else
			soft declare sub CFRunLoopRemoveTimer lib CarbonLib (rl as Ptr, t as Ptr, mode as Ptr)
			
			CFRunLoopRemoveTimer MainRunLoop, me, CFBundle.CarbonFramework.DataPointerNotRetained(kCFRunLoopCommonModes).Ptr(0)
			end if
			#endif
			End Set
		#tag EndSetter
		Enabled As Boolean
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			#if targetMacOS
			soft declare function CFRunLoopTimerDoesRepeat lib CarbonLib ( t as Ptr) as Boolean
			
			return CFRunLoopTimerDoesRepeat(me)
			#endif
			End Get
		#tag EndGetter
		IsRepeating As Boolean
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			#if targetMacOS
			soft declare function CFRunLoopTimerGetInterval lib CarbonLib (t as Ptr) as Double
			return CFRunLoopTimerGetInterval(me)
			#endif
			End Get
		#tag EndGetter
		Period As Double
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			#if targetMacOS
			soft declare function CFRunLoopTimerIsValid lib CarbonLib (t as Ptr) as Boolean
			return CFRunLoopTimerIsValid(me)
			#endif
			End Get
		#tag EndGetter
		IsValid As Boolean
	#tag EndComputedProperty


	#tag Constant, Name = kCFRunLoopCommonModes, Type = String, Dynamic = False, Default = \"kCFRunLoopCommonModes", Scope = Private
	#tag EndConstant

	#tag Constant, Name = UnixEpoch, Type = Double, Dynamic = False, Default = \"3061152000.0", Scope = Private
	#tag EndConstant


	#tag ViewBehavior
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			Type="Integer"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Description"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
			InheritedFrom="CFType"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Enabled"
			Group="Behavior"
			InitialValue="0"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="IsRepeating"
			Group="Behavior"
			InitialValue="0"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Period"
			Group="Behavior"
			InitialValue="0"
			Type="Double"
		#tag EndViewProperty
		#tag ViewProperty
			Name="IsValid"
			Group="Behavior"
			InitialValue="0"
			Type="Boolean"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass