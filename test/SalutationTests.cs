using System;
using Xunit;
using dependency;

namespace dependency.test
{
    public class SalutationTests
    {
        #region construction & formatting tests
        
        [Fact]
        public void ShouldStartWithTheHelloGreetingKeyword()
        {
            var salutation = initSalutation();
            Assert.StartsWith("Hello", salutation.Compose("there"));
        }

        [Fact]
        public void ShouldEndTheGreetingWithSuppliedAudience()
        {
            var salutation = initSalutation();
            var audience = "folks";
            Assert.EndsWith(audience, salutation.Compose(audience));
        }

        #endregion

        #region boundary testing
        
        [Fact]
        public void ShouldThrowExceptionWhenProvidedNullAudience()
        {
            var salutation = initSalutation();
            Assert.Throws<ArgumentNullException>(() => salutation.Compose(null));
        }

        [Fact]
        public void ShouldThrowExceptionWhenProvidedEmptyAudience()
        {
            var salutation = initSalutation();
            Assert.Throws<ArgumentNullException>(() => salutation.Compose(string.Empty));
        }

        [Fact]
        public void ShouldThrowExceptionWhenProvidedWhitespaceAudience()
        {
            var salutation = initSalutation();
            Assert.Throws<ArgumentNullException>(() => salutation.Compose("  "));
        }
        
        #endregion

        #region factories/helpers/initializers

        private Salutation initSalutation() {
            return new Salutation();
        }
        
        #endregion
    }
}
