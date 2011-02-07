The SignalCommandMap is an extension for the Robotlegs-AS3 micro-architecture that makes use of AS3-Signals to trigger commands.
Extented to be able to map signal class definition (for Deluxe Signal) to commands.

Somewhere in the bootstrap
//	map the RemoteConnectionFaultSignal signal Definition to the RemoteConnectionFaultCommand
	signalCommandMap.mapSignalDefinitionCommand( RemoteConnectionFaultSignal, RemoteConnectionFaultCommand );

In our services
//  create the fault signal for this Service
	onFault = new RemoteConnectionFaultSignal( this );
	signalCommandMap.mapSignalDefinitionInstance(RemoteConnectionFaultSignal, onFault);
	
Created this to be able to have one handler for error signal dispatched by the services library for robotleg I'm developing (soon on github).

[Requires Robotlegs 1.1](http://github.com/robotlegs/robotlegs-framework)