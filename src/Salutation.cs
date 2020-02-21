using System;

namespace dependency
{
    public class Salutation
    {
        public string Compose(string audience) 
        {
            /* if (audience == null) {
                // do something goofy to violate rule.
                int target = -5;
                int num = 3;

                target =- num;  // Noncompliant; target = -3. Is that really what's meant?
                target =+ num; // Noncompliant; target = 3

                GC.Collect(2, GCCollectionMode.Optimized); // Noncompliant

            }*/

            if (string.IsNullOrWhiteSpace(audience)) 
            {
                throw new ArgumentNullException("You need to address an audience.");
            }

            //TODO: make sure the audience is not a swear word.

            return "Hello " + audience;
            // return 
            // return $"Hello {audience}";
        }

        /* public void Foo()
        {
            var g = new Guid(); // Noncompliant - what's the intent?
        }
        */
    }
}