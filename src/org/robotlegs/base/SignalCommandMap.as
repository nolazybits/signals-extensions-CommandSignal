package org.robotlegs.base
{
	import org.osflash.signals.ISignal;
    import org.osflash.signals.ISignalOwner;
    import org.robotlegs.core.IInjector;
	import org.robotlegs.core.ISignalCommandMap;

	import flash.utils.Dictionary;
	import flash.utils.describeType;

	public class SignalCommandMap implements ISignalCommandMap
    {
        protected var injector					:IInjector;
        protected var signalMap					:Dictionary;
        protected var signalDefinitionMap		:Dictionary;
        protected var signalClassMap			:Dictionary;
        protected var verifiedCommandClasses	:Dictionary;

        public function SignalCommandMap(injector:IInjector)
        {
            this.injector 			= injector;
            signalMap 				= new Dictionary( false );
			signalDefinitionMap		= new Dictionary( false );
            signalClassMap 			= new Dictionary( false );
            verifiedCommandClasses	= new Dictionary( false );
        }

        public function mapSignal(signal:ISignal, commandClass:Class, oneShot:Boolean = false):void
        {
            verifyCommandClass( commandClass );
            if ( hasSignalCommand( signal, commandClass ) )
                return;
            var signalCommandMap:Dictionary = signalMap[signal] ||= new Dictionary( false );
            var callback:Function = function(a:* = null, b:* = null, c:* = null, d:* = null, e:* = null, f:* = null, g:* = null):void
            {
                routeSignalToCommand( signal, arguments, commandClass, oneShot );
            };

            signalCommandMap[commandClass] = callback;
            signal.add( callback );
        }
		
        public function mapSignalClass(signalClass:Class, commandClass:Class, oneshot:Boolean = false):ISignal
        {
            var signal:ISignal = getSignalClassInstance( signalClass );
            mapSignal( signal, commandClass, oneshot );
            return signal;
        }

        private function getSignalClassInstance(signalClass:Class):ISignal
        {
            return ISignal(signalClassMap[signalClass]) || createSignalClassInstance(signalClass);
        }

        private function createSignalClassInstance(signalClass:Class):ISignal
        {
            var injectorForSignalInstance:IInjector = injector;
            var signal:ISignal;
            if(injector.hasMapping(IInjector))
                injectorForSignalInstance = injector.getInstance(IInjector);
            signal = injectorForSignalInstance.instantiate( signalClass );
            injectorForSignalInstance.mapValue( signalClass, signal );
            signalClassMap[signalClass] = signal;
            return signal;
        }

        public function hasSignalCommand(signal:ISignal, commandClass:Class):Boolean
        {
            var callbacksByCommandClass:Dictionary = signalMap[signal];
            if ( callbacksByCommandClass == null ) return false;
            var callback:Function = callbacksByCommandClass[commandClass];
            return callback != null;
        }

        public function unmapSignal(signal:ISignal, commandClass:Class):void
        {
            var callbacksByCommandClass:Dictionary = signalMap[signal];
            if ( callbacksByCommandClass == null ) return;
            var callback:Function = callbacksByCommandClass[commandClass];
            if ( callback == null ) return;
            signal.remove( callback );
            delete callbacksByCommandClass[commandClass];
        }

        public function unmapSignalClass(signalClass:Class, commandClass:Class):void
        {
			unmapSignal(getSignalClassInstance(signalClass), commandClass);
		}

        protected function routeSignalToCommand(signal:ISignal, valueObjects:Array, commandClass:Class, oneshot:Boolean):void
        {
            createCommandInstance(signal.valueClasses, valueObjects, commandClass).execute();

            if ( oneshot )
                unmapSignal( signal, commandClass );
        }
        protected function createCommandInstance(valueClasses:Array, valueObjects:Array, commandClass:Class):Object
        {
			for (var i:uint=0;i<valueClasses.length;i++)
			{
				injector.mapValue(valueClasses[i], valueObjects[i]);
			}
            return injector.instantiate(commandClass);
        }

        protected function verifyCommandClass(commandClass:Class):void
        {
            if ( verifiedCommandClasses[commandClass] ) return;
			if (describeType( commandClass ).factory.method.(@name == "execute").length() != 1)
			{
				throw new ContextError( ContextError.E_COMMANDMAP_NOIMPL + ' - ' + commandClass );
			}
			verifiedCommandClasses[commandClass] = true;
        }

        public function mapSignalDefinitionCommand( signalDefinition : Class, commandClass : Class, oneshot : Boolean = false ) : void
        {
            verifyCommandClass( commandClass );
            if ( hasSignalDefinitionCommand( signalDefinition, commandClass ) )
                return;
            var signalDefinitionObject:Object = signalDefinitionMap[signalDefinition] ||= { signalInstances : [], commandMap : new Dictionary( false ) };
            var callback:Function = function(a:* = null, b:* = null, c:* = null, d:* = null, e:* = null, f:* = null, g:* = null):void
            {
                routeSignalDefinitionToCommand(signalDefinition, arguments, commandClass, oneshot );
            };
            signalDefinitionObject.commandMap[commandClass] = callback;
            bindSignalDefinitionCommand(signalDefinition);
        }

        public function mapSignalDefinitionInstance( signalDefinition : Class, signalInstance : ISignal, throwError : Boolean = true ) : void
        {
            //	check if the instance of the signal has been registered already
            if ( hasSignalDefinitionInstance( signalDefinition, signalInstance ) ) return;
            signalDefinitionMap[signalDefinition].signalInstances.push( signalInstance );

            bindSignalDefinitionCommand(signalDefinition);
        }

        public function hasSignalDefinitionCommand(signalDefinition:Class, commandClass:Class):Boolean
        {
            var signalDefinitionObject:Object = signalDefinitionMap[signalDefinition];
            if ( signalDefinitionObject == null ) return false;
            var commandMap:Dictionary = signalDefinitionObject.commandMap as Dictionary;
            if ( commandMap == null ) return false;
            var callback:Function = commandMap[commandClass];
            return callback != null;
        }

        public function hasSignalDefinitionInstance (signalDefinition:Class, signalInstance:ISignal ) : Boolean
        {
            var signalDefinitionObject:Object = signalDefinitionMap[signalDefinition];
            if ( signalDefinitionObject == null ) return false;
            var signalInstances:Array = signalDefinitionObject.signalInstances as Array;
            if ( signalInstances == null ) return false;
            return signalInstances.indexOf(signalInstance) != -1;
        }

        public function unmapSignalDefinitionCommand (signalDefinition:Class, commandClass:Class):void
        {
            if ( !hasSignalDefinitionCommand(signalDefinition, commandClass) )
                return;
            var signalDefinitionObject:Object = signalDefinitionMap[signalDefinition] as Object;
            var command : Function = signalDefinitionObject.commandMap[commandClass] as Function;
            for each( var signal : ISignal in signalDefinitionObject.signalInstances )
            {
                signal.remove( command );
            }
            var commandMap:Dictionary = signalDefinitionObject.commandMap;
            delete commandMap[commandClass];
        }

        protected function routeSignalDefinitionToCommand( signalDefinition : Class, valueObjects:Array, commandClass:Class, oneshot:Boolean ) : void
        {
            var signalInstances : Array = signalDefinitionMap[signalDefinition].signalInstances as Array;
            for each ( var signal : ISignal in signalInstances )
            {
                createCommandInstance(signal.valueClasses, valueObjects, commandClass).execute();
            }
            if ( oneshot )
                unmapSignalDefinitionCommand(signalDefinition, commandClass );

        }

        protected function bindSignalDefinitionCommand( signalDefinition : Class ) : void
        {
            for each ( var signal : ISignalOwner in signalDefinitionMap[signalDefinition].signalInstances )
            {
                signal.removeAll();
                for each( var command : Function in  signalDefinitionMap[signalDefinition].commandMap )
                {
                    signal.add( command );
                }
            }
        }
    }
}
