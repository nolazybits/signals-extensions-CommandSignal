package org.robotlegs.base
{
    import flash.utils.Dictionary;
    import flash.utils.describeType;
    import flash.utils.getDefinitionByName;

    import flash.utils.getQualifiedClassName;

    import org.osflash.signals.ISignal;
    import org.robotlegs.core.IInjector;
    import org.robotlegs.core.ISignalCommandMap;
    import org.robotlegs.vo.SignalDefinition;

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

        protected function getSignalClassInstance(signalClass:Class):ISignal
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
            mapSignalValues( signal.valueClasses, valueObjects );
            createCommandInstance( commandClass).execute();
            unmapSignalValues( signal.valueClasses, valueObjects );
            if ( oneshot )
                unmapSignal( signal, commandClass );
        }
        protected function createCommandInstance(commandClass:Class):Object {
            return injector.instantiate(commandClass);
        }

        protected function mapSignalValues(valueClasses:Array, valueObjects:Array):void {
            for (var i:uint = 0; i < valueClasses.length; i++) {
                injector.mapValue(valueClasses[i], valueObjects[i]);
            }
        }

        protected function unmapSignalValues(valueClasses:Array, valueObjects:Array):void {
            for (var i:uint = 0; i < valueClasses.length; i++) {
                injector.unmap(valueClasses[i]);
            }
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
            var o : SignalDefinition = signalDefinitionMap[signalDefinition] ||= new SignalDefinition();
            if ( hasSignalDefinitionCommand( signalDefinition, commandClass ) )
            {
                return;
            }

            var callback:Function = function(a:* = null, b:* = null, c:* = null, d:* = null, e:* = null, f:* = null, g:* = null):void
            {
                routeSignalDefinitionToCommand(signalDefinition, arguments, commandClass, oneshot );
            };
            o.mapCommand(commandClass, callback);
        }

        public function mapSignalDefinitionInstance( signalInstance : ISignal, throwError : Boolean = true ) : void
        {
        //  get the definition of the signal
            var signalDefinition : * = getDefinitionByName( getQualifiedClassName( signalInstance) ) as Class;
        //  get the object or create a new one and push it
            var o : SignalDefinition = signalDefinitionMap[signalDefinition] ||= new SignalDefinition();
        //	check if the instance of the signal has been registered already
            if ( hasSignalDefinitionInstance( signalInstance ) ) return;
        //  add the signal to the array
            o.mapInstance( signalInstance );
        }

        public function hasSignalDefinition( signalDefinition:Class ) : Boolean
        {
           return signalDefinitionMap[signalDefinition] != null;
        }

        public function hasSignalDefinitionCommand(signalDefinition:Class, commandClass:Class):Boolean
        {
            if ( !hasSignalDefinition(signalDefinition) ) return false;
            var o : SignalDefinition =  signalDefinitionMap[signalDefinition];
            return o.hasCommand(commandClass);
        }

        public function hasSignalDefinitionInstance ( signalInstance : ISignal ) : Boolean
        {
            var signalDefinition : * = getDefinitionByName( getQualifiedClassName( signalInstance) ) as Class;

            if ( !hasSignalDefinition(signalDefinition) ) return false;
            var o : SignalDefinition =  signalDefinitionMap[signalDefinition];
            return o.hasInstance( signalInstance );
        }

        public function unmapSignalDefinition( signalDefinition : Class ) : void
        {
        //	check if the instance of the signal has been registered
            if ( !hasSignalDefinition(signalDefinition) ) return;
            var o : SignalDefinition = signalDefinitionMap[signalDefinition];
            o.unmapInstances();
            o.unmapCommands();
        //  finally remove the definition
            delete signalDefinitionMap[signalDefinition];
        }

        public function unmapSignalDefinitionCommand (signalDefinition:Class, commandClass:Class):void
        {
            if ( !hasSignalDefinitionCommand(signalDefinition, commandClass) )
                return;
            var o : SignalDefinition = signalDefinitionMap[signalDefinition];
            o.unmapCommand( commandClass );
        }

        public function unmapSignalDefinitionInstance( signalInstance : ISignal ) : void
        {
        //  get the definition of the signal
            var signalDefinition : * = getDefinitionByName( getQualifiedClassName( signalInstance) ) as Class;
        //	check if the instance of the signal has been registered
            if ( hasSignalDefinitionInstance( signalInstance ) ) return;
        //  remove any listener
            signalInstance.removeAll();
        //  and remove it from the array
            var o : SignalDefinition = signalDefinitionMap[signalDefinition];
            o.unmapInstance(signalInstance);
        }


        protected function routeSignalDefinitionToCommand( signalDefinition : Class, valueObjects:Array, commandClass:Class, oneshot:Boolean ) : void
        {
            var signalInstances : Array = signalDefinitionMap[signalDefinition].signalInstances as Array;
            for each ( var signal : ISignal in signalInstances )
            {
                mapSignalValues( signal.valueClasses, valueObjects );
                createCommandInstance(commandClass).execute();
                unmapSignalValues( signal.valueClasses, valueObjects );
            }
            if ( oneshot )
                unmapSignalDefinitionCommand(signalDefinition, commandClass );

        }
    }
}
