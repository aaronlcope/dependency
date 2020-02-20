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

            //TODO: make sure the audience is not a swear word.

            return "Hello " + audience;
            // return 
            // return $"Hello {audience}";
        }
    }
}