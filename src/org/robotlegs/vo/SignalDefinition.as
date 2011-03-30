/**
 * User: xavier
 * Date: 2/10/11
 * Time: 5:54 PM
 */
package org.robotlegs.vo
{
    import flash.utils.Dictionary;

    import flash.utils.getQualifiedClassName;

    import org.osflash.signals.ISignal;

    public class SignalDefinition
    {
        private var __signalInstances   : Dictionary;
        private var __commandMap        : Dictionary;

        public function SignalDefinition ()
        {
            __signalInstances = new Dictionary(false);
            __commandMap = new Dictionary(false);
        }
    // ************************************************************************
    // * PUBLIC FUNCTIONS
    // ************************************************************************
        public function hasInstance( signalInstance : ISignal ) : Boolean
        {
            var className : String = getQualifiedClassName( signalInstance );
            return __signalInstances[className] != null;
        }

        public function hasCommand( commandClass : Class ) : Boolean
        {
           return __commandMap[commandClass] != null;
        }

        public function mapCommand(commandClass : Class, callback : Function ) : void
        {
             __commandMap[commandClass] = callback;
            _bindSignalDefinitionCommand();
        }

        public function mapInstance( signalInstance : ISignal ) : void
        {
            var className : String = getQualifiedClassName( signalInstance );
            __signalInstances[className] = signalInstance;
            _bindSignalDefinitionCommand(signalInstance);
        }

        public function unmapCommand( commandClass : Class ) : void
        {
            var command : Function = __commandMap[commandClass] as Function;
            for each( var signal : ISignal in __signalInstances )
            {
                signal.remove( command );
            }
            delete __commandMap[commandClass];
        }

        public function unmapCommands() : void
        {
        //  remove all the command, iterates through each key
            for (var key : Object in __commandMap)
            {
                unmapCommand( key as Class  );
            }
            for each ( var command : Function in __commandMap )
                unmapCommand( __commandMap[key] )
        }

        public function unmapInstance( signalInstance : ISignal ) : void
        {
            if ( !hasInstance(signalInstance) ) return;
            var className : String = getQualifiedClassName(signalInstance);
            signalInstance.removeAll();
            delete __signalInstances[className];
        }

        public function unmapInstances() : void
        {
        //  if it exists get loop in all the signals, removing all the listeners
            var signalInstance  : ISignal;
            var className       : String;
            for ( className in __signalInstances )
            {
                signalInstance = __signalInstances[className];
                signalInstance.removeAll();
                delete __signalInstances[className];
            }
        }

    // ************************************************************************
    // * GETTER & SETTER
    // ************************************************************************
        public function get commandMap() : Dictionary
        {
            var cloned:Dictionary = new Dictionary(true);
            for(var key:Object in __commandMap) {
                cloned[key] = __commandMap[key];
            }
            return cloned;
        }
        public function get signalInstances() : Array
        {
            var signalInstance : ISignal;
            var tmp : Array = [];
            for each( signalInstance in __signalInstances)
                tmp.push(signalInstance);
            return tmp;
        }

    // ************************************************************************
    // * PROTECTED FUNCTIONS
    // ************************************************************************
        protected function _bindSignalDefinitionCommand( signalInstance : ISignal = null ) : void
        {
            var command : Function;
        //  bind/rebind all the commands for this signal only
            if ( signalInstance )
            {
                if( hasInstance(signalInstance) )
                {
                    (signalInstance as ISignal).removeAll();
                    for each( command  in  __commandMap )
                    {
                        signalInstance.add( command );
                    }
                }
            }
        //  rebind all the signal to the commands for this signal definition
            else
            {
                for each ( var signal : ISignal in __signalInstances )
                {
                    signal.removeAll();
                    for each( command  in  __commandMap )
                    {
                        signal.add( command );
                    }
                }
            }
        }


    // ************************************************************************
    // * GETTER & SETTER
    // ************************************************************************
    /*    public function get signalInstances ():Array { return __signalInstances; }
        public function set signalInstances (value:Array):void
        {
            __signalInstances = value;
        }

        public function get commandMap ():Dictionary { return __commandMap; }
        public function set commandMap (value:Dictionary):void
        {
            __commandMap = value;
        } */
    }
}
