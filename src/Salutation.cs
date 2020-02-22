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
    }
}