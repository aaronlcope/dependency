using System;

namespace dependency
{
    public class Salutation
    {
        public string Compose(string audience) 
        {
            if (string.IsNullOrWhiteSpace(audience)) 
            {
                throw new ArgumentNullException(nameof(audience), "You need to address an audience.");
            }

            return $"Hello {audience}";
        }
    }
}