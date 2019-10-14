using ReactNative.Bridge;
using System;
using System.Collections.Generic;
using Windows.ApplicationModel.Core;
using Windows.UI.Core;

namespace Tinkoff.Asdk.RNTinkoffAsdk
{
    /// <summary>
    /// A module that allows JS to share data.
    /// </summary>
    class RNTinkoffAsdkModule : NativeModuleBase
    {
        /// <summary>
        /// Instantiates the <see cref="RNTinkoffAsdkModule"/>.
        /// </summary>
        internal RNTinkoffAsdkModule()
        {

        }

        /// <summary>
        /// The name of the native module.
        /// </summary>
        public override string Name
        {
            get
            {
                return "RNTinkoffAsdk";
            }
        }
    }
}
