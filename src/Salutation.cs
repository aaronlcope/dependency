using System;

namespace dependency
{
    public class Salutation
    {
        public string Compose(string audience) 
        {
            if (string.IsNullOrWhiteSpace(audience)) 
            {
                throw new ArgumentNullException("You need to address an audience.");
            }

            return "Hello " + audience;
        }

        public void DoNothing {
            //adding some more debt for example purposes.
        }
    }
}