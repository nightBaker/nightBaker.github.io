---
layout: post
title: Encrypt and decrypt data with PGP on .net core
date:       2019-02-08
summary:    Encrypt and decrypt files with bouncy castle library using pgp on .net core
categories: pgp cryptography .net core
---

## Problem.

We need to encrypt file with pgp algorithm by public key. 
In order to Client could trust our data and know that even we can't read secret data.
Client could give us public key for encryption so only he can decrypt data by private key.

OpenPGP - encryption standart.

## Library 

There is famous library called BouncyCastle for working with different ecnryption decryption algorithms in .net world. It also contains pgp algorithm.
So if we download source code and example from official [website](http://git.bouncycastle.org/csharp/index.html). We can see pgp example showing how to encrypt and decrypt file using pgp algorithm.

First of all we need next nuget packages
```powershell
Install-Package  BouncyCastle.NetCore
Install-Package  BouncyCastle.NetCoreSdk
```

Following official example, we need only few classes

```c#
 public class Pgp
    {
        public static void DecryptFile(
            string inputFileName,
            string keyFileName,
            char[] passwd,
            string defaultFileName)
        {
            using (Stream input = File.OpenRead(inputFileName),
                   keyIn = File.OpenRead(keyFileName))
            {
                DecryptFile(input, keyIn, passwd, defaultFileName);
            }
        }

        /**
		 * decrypt the passed in message stream
		 */
        private static void DecryptFile(
            Stream inputStream,
            Stream keyIn,
            char[] passwd,
            string defaultFileName)
        {
            inputStream = PgpUtilities.GetDecoderStream(inputStream);

            try
            {
                PgpObjectFactory pgpF = new PgpObjectFactory(inputStream);
                PgpEncryptedDataList enc;

                PgpObject o = pgpF.NextPgpObject();
                //
                // the first object might be a PGP marker packet.
                //
                if (o is PgpEncryptedDataList)
                {
                    enc = (PgpEncryptedDataList)o;
                }
                else
                {
                    enc = (PgpEncryptedDataList)pgpF.NextPgpObject();
                }

                //
                // find the secret key
                //
                PgpPrivateKey sKey = null;
                PgpPublicKeyEncryptedData pbe = null;
                PgpSecretKeyRingBundle pgpSec = new PgpSecretKeyRingBundle(
                    PgpUtilities.GetDecoderStream(keyIn));

                foreach (PgpPublicKeyEncryptedData pked in enc.GetEncryptedDataObjects())
                {
                    sKey = PgpExampleUtilities.FindSecretKey(pgpSec, pked.KeyId, passwd);

                    if (sKey != null)
                    {
                        pbe = pked;
                        break;
                    }
                }

                if (sKey == null)
                {
                    throw new ArgumentException("secret key for message not found.");
                }

                Stream clear = pbe.GetDataStream(sKey);

                PgpObjectFactory plainFact = new PgpObjectFactory(clear);

                PgpObject message = plainFact.NextPgpObject();

                if (message is PgpCompressedData)
                {
                    PgpCompressedData cData = (PgpCompressedData)message;
                    PgpObjectFactory pgpFact = new PgpObjectFactory(cData.GetDataStream());

                    message = pgpFact.NextPgpObject();
                }

                if (message is PgpLiteralData)
                {
                    PgpLiteralData ld = (PgpLiteralData)message;

                    string outFileName = ld.FileName;
                    if (outFileName.Length == 0)
                    {
                        outFileName = defaultFileName;
                    }

                    Stream fOut = File.Create(outFileName);
                    Stream unc = ld.GetInputStream();
                    Streams.PipeAll(unc, fOut);
                    fOut.Close();
                }
                else if (message is PgpOnePassSignatureList)
                {
                    throw new PgpException("encrypted message contains a signed message - not literal data.");
                }
                else
                {
                    throw new PgpException("message is not a simple encrypted file - type unknown.");
                }

                if (pbe.IsIntegrityProtected())
                {
                    if (!pbe.Verify())
                    {
                        Console.Error.WriteLine("message failed integrity check");
                    }
                    else
                    {
                        Console.Error.WriteLine("message integrity check passed");
                    }
                }
                else
                {
                    Console.Error.WriteLine("no message integrity check");
                }
            }
            catch (PgpException e)
            {
                Console.Error.WriteLine(e);

                Exception underlyingException = e.InnerException;
                if (underlyingException != null)
                {
                    Console.Error.WriteLine(underlyingException.Message);
                    Console.Error.WriteLine(underlyingException.StackTrace);
                }
            }
        }

        public static void EncryptFile(
            string outputFileName,
            string inputFileName,
            string encKeyFileName,
            bool armor,
            bool withIntegrityCheck)
        {
            PgpPublicKey encKey = PgpExampleUtilities.ReadPublicKey(encKeyFileName);

            using (Stream output = File.Create(outputFileName))
            {
                EncryptFile(output, inputFileName, encKey, armor, withIntegrityCheck);
            }
        }

        private static void EncryptFile(
            Stream outputStream,
            string fileName,
            PgpPublicKey encKey,
            bool armor,
            bool withIntegrityCheck)
        {
            if (armor)
            {
                outputStream = new ArmoredOutputStream(outputStream);
            }

            try
            {
                byte[] bytes = PgpExampleUtilities.CompressFile(fileName, CompressionAlgorithmTag.Zip);

                PgpEncryptedDataGenerator encGen = new PgpEncryptedDataGenerator(
                    SymmetricKeyAlgorithmTag.Cast5, withIntegrityCheck, new SecureRandom());
                encGen.AddMethod(encKey);

                Stream cOut = encGen.Open(outputStream, bytes.Length);

                cOut.Write(bytes, 0, bytes.Length);
                cOut.Close();

                if (armor)
                {
                    outputStream.Close();
                }
            }
            catch (PgpException e)
            {
                Console.Error.WriteLine(e);

                Exception underlyingException = e.InnerException;
                if (underlyingException != null)
                {
                    Console.Error.WriteLine(underlyingException.Message);
                    Console.Error.WriteLine(underlyingException.StackTrace);
                }
            }
        }
    }
```

```c#
 public class PgpExampleUtilities
    {
        /**
		 * Search a secret key ring collection for a secret key corresponding to keyID if it
		 * exists.
		 * 
		 * @param pgpSec a secret key ring collection.
		 * @param keyID keyID we want.
		 * @param pass passphrase to decrypt secret key with.
		 * @return
		 * @throws PGPException
		 * @throws NoSuchProviderException
		 */
        internal static PgpPrivateKey FindSecretKey(PgpSecretKeyRingBundle pgpSec, long keyID, char[] pass)
        {
            PgpSecretKey pgpSecKey = pgpSec.GetSecretKey(keyID);

            if (pgpSecKey == null)
            {
                return null;
            }

            return pgpSecKey.ExtractPrivateKey(pass);
        }

        internal static PgpPublicKey ReadPublicKey(string fileName)
        {
            using (Stream keyIn = File.OpenRead(fileName))
            {
                return ReadPublicKey(keyIn);
            }
        }

        internal static PgpPublicKey ReadPublicKey(Stream input)
        {
            PgpPublicKeyRingBundle pgpPub = new PgpPublicKeyRingBundle(
                PgpUtilities.GetDecoderStream(input));

            //
            // we just loop through the collection till we find a key suitable for encryption, in the real
            // world you would probably want to be a bit smarter about this.
            //

            foreach (PgpPublicKeyRing keyRing in pgpPub.GetKeyRings())
            {
                foreach (PgpPublicKey key in keyRing.GetPublicKeys())
                {
                    if (key.IsEncryptionKey)
                    {
                        return key;
                    }
                }
            }

            throw new ArgumentException("Can't find encryption key in key ring.");
        }


        internal static byte[] CompressFile(string fileName, CompressionAlgorithmTag algorithm)
        {
            MemoryStream bOut = new MemoryStream();
            PgpCompressedDataGenerator comData = new PgpCompressedDataGenerator(algorithm);
            PgpUtilities.WriteFileToLiteralData(comData.Open(bOut), PgpLiteralData.Binary,
                new FileInfo(fileName));
            comData.Close();
            return bOut.ToArray();
        }
    }
```

```c#
 public class Streams
    {
        private const int BufferSize = 512;

        public static void PipeAll(Stream inStr, Stream outStr)
        {
            byte[] bs = new byte[BufferSize];
            int numRead;
            while ((numRead = inStr.Read(bs, 0, bs.Length)) > 0)
            {
                outStr.Write(bs, 0, numRead);
            }
        }
    }
```

Now we can write small test to check it. You can generate pgp keys [here](https://www.igolder.com/pgp/generate-key/)

```c#
            Pgp.EncryptFile("Resources/output.txt", "Resources/input.txt", "Resources/publicKey.txt", true, true);

            Pgp.DecryptFile("Resources/output.txt", "Resources/privateKey.txt", "pass".ToCharArray(), "default.txt");

```

if we open our ```output.txt``` file we can see such content

```
-----BEGIN PGP MESSAGE-----
Version: BCPG C# v1.9.0.0

hQEMA/r7BVY9J2TEAQf/XbMEsR+5YgmGi00g++c1NwpP/R+6D52cbAW8gQZjSWm/
Of2I4llMw9YFzrGutWnx5gbFlcerEw66zozfdQY1QXn9Q4zPMoBV4UX95ImjXgcp
OyXPoB2Z4O5zxsusGmQrUhaStEEvP5vWr9Pbt+JBHvUKtxPQ4n5iwRapCSHeVuwz
tsUesrz3z3OGBtr6LDhIY9Y7VuuGWeTbdv6SlDGbgJ/hYT78yIhCqMHtu7Wnqcii
JjGetCNrS1sbrLP9avTqV8jAuBSeMBpH9giUS8GqMpjQeHS7SfPOPMX3nczVumHD
t2U/a7FA4Zl74ROK5Sa7VligpSHlqve0QYK0lTpuz9JMAZWwaxBREsWY0G/TfAQV
5xteGI6vL9+MkDMkP+20gz3PljEbzZLb76d6b864qOr2GT/88FiPW2RVEBjNs2cr
ZfhYXmYbUTSV+b/4Cg==
=DaO6
-----END PGP MESSAGE-----
```

However we not always work with files on disk. It is more convinient to abstract of source of file and work with array of bytes as input data.
The solution is described on [stackOverflow](https://stackoverflow.com/questions/4192296/c-sharp-how-to-simply-encrypt-a-text-file-with-a-pgp-public-key).
And looks like that:

```c#
   public class Pgp
    {
        /**
    * A simple routine that opens a key ring file and loads the first available key suitable for
    * encryption.
    *
    * @param in
    * @return
    * @m_out
    * @
    */
        public static PgpPublicKey ReadPublicKey(Stream inputStream)
        {
            inputStream = PgpUtilities.GetDecoderStream(inputStream);
            PgpPublicKeyRingBundle pgpPub = new PgpPublicKeyRingBundle(inputStream);
            //
            // we just loop through the collection till we find a key suitable for encryption, in the real
            // world you would probably want to be a bit smarter about this.
            //
            //
            // iterate through the key rings.
            //
            foreach (PgpPublicKeyRing kRing in pgpPub.GetKeyRings())
            {
                foreach (PgpPublicKey k in kRing.GetPublicKeys())
                {
                    if (k.IsEncryptionKey)
                        return k;
                }
            }

            throw new ArgumentException("Can't find encryption key in key ring.");
        }

        /**
        * Search a secret key ring collection for a secret key corresponding to
        * keyId if it exists.
        *
        * @param pgpSec a secret key ring collection.
        * @param keyId keyId we want.
        * @param pass passphrase to decrypt secret key with.
        * @return
        */
        private static PgpPrivateKey FindSecretKey(PgpSecretKeyRingBundle pgpSec, long keyId, char[] pass)
        {
            PgpSecretKey pgpSecKey = pgpSec.GetSecretKey(keyId);
            if (pgpSecKey == null)
                return null;

            return pgpSecKey.ExtractPrivateKey(pass);
        }

        /**
        * Decrypt the byte array passed into inputData and return it as
        * another byte array.
        *
        * @param inputData - the data to decrypt
        * @param keyIn - a stream from your private keyring file
        * @param passCode - the password
        * @return - decrypted data as byte array
        */
        public static byte[] Decrypt(byte[] inputData, Stream keyIn, string passCode)
        {
            byte[] error = Encoding.ASCII.GetBytes("ERROR");

            Stream inputStream = new MemoryStream(inputData);
            inputStream = PgpUtilities.GetDecoderStream(inputStream);
            MemoryStream decoded = new MemoryStream();

            try
            {
                PgpObjectFactory pgpF = new PgpObjectFactory(inputStream);
                PgpEncryptedDataList enc;
                PgpObject o = pgpF.NextPgpObject();

                //
                // the first object might be a PGP marker packet.
                //
                if (o is PgpEncryptedDataList)
                    enc = (PgpEncryptedDataList)o;
                else
                    enc = (PgpEncryptedDataList)pgpF.NextPgpObject();

                //
                // find the secret key
                //
                PgpPrivateKey sKey = null;
                PgpPublicKeyEncryptedData pbe = null;
                PgpSecretKeyRingBundle pgpSec = new PgpSecretKeyRingBundle(
                PgpUtilities.GetDecoderStream(keyIn));
                foreach (PgpPublicKeyEncryptedData pked in enc.GetEncryptedDataObjects())
                {
                    sKey = FindSecretKey(pgpSec, pked.KeyId, passCode.ToCharArray());
                    if (sKey != null)
                    {
                        pbe = pked;
                        break;
                    }
                }
                if (sKey == null)
                    throw new ArgumentException("secret key for message not found.");

                Stream clear = pbe.GetDataStream(sKey);
                PgpObjectFactory plainFact = new PgpObjectFactory(clear);
                PgpObject message = plainFact.NextPgpObject();

                if (message is PgpCompressedData)
                {
                    PgpCompressedData cData = (PgpCompressedData)message;
                    PgpObjectFactory pgpFact = new PgpObjectFactory(cData.GetDataStream());
                    message = pgpFact.NextPgpObject();
                }
                if (message is PgpLiteralData)
                {
                    PgpLiteralData ld = (PgpLiteralData)message;
                    Stream unc = ld.GetInputStream();
                    PipeAll(unc, decoded);
                }
                else if (message is PgpOnePassSignatureList)
                    throw new PgpException("encrypted message contains a signed message - not literal data.");
                else
                    throw new PgpException("message is not a simple encrypted file - type unknown.");

                if (pbe.IsIntegrityProtected())
                {
                    //if (!pbe.Verify())
                    //    MessageBox.Show(null, "Message failed integrity check.", "PGP Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    //else
                    //    MessageBox.Show(null, "Message integrity check passed.", "PGP Error", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
                else
                {
                    //MessageBox.Show(null, "No message integrity check.", "PGP Error", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }

                return decoded.ToArray();
            }
            catch (Exception e)
            {
                //if (e.Message.StartsWith("Checksum mismatch"))
                //    MessageBox.Show(null, "Likely invalid passcode. Possible data corruption.", "Invalid Passcode", MessageBoxButtons.OK, MessageBoxIcon.Error);
                //else if (e.Message.StartsWith("Object reference not"))
                //    MessageBox.Show(null, "PGP data does not exist.", "PGP Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                //else if (e.Message.StartsWith("Premature end of stream"))
                //    MessageBox.Show(null, "Partial PGP data found.", "PGP Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                //else
                //    MessageBox.Show(null, e.Message, "PGP Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                //Exception underlyingException = e.InnerException;
                //if (underlyingException != null)
                //    MessageBox.Show(null, underlyingException.Message, "PGP Error", MessageBoxButtons.OK, MessageBoxIcon.Error);

                return error;
            }
        }

        /**
        * Encrypt the data.
        *
        * @param inputData - byte array to encrypt
        * @param passPhrase - the password returned by "ReadPublicKey"
        * @param withIntegrityCheck - check the data for errors
        * @param armor - protect the data streams
        * @return - encrypted byte array
        */
        public static byte[] Encrypt(byte[] inputData, PgpPublicKey passPhrase, bool withIntegrityCheck, bool armor)
        {
            byte[] processedData = Compress(inputData, PgpLiteralData.Console, CompressionAlgorithmTag.Uncompressed);

            MemoryStream bOut = new MemoryStream();
            Stream output = bOut;

            if (armor)
                output = new ArmoredOutputStream(output);

            PgpEncryptedDataGenerator encGen = new PgpEncryptedDataGenerator(SymmetricKeyAlgorithmTag.Cast5, withIntegrityCheck, new SecureRandom());
            encGen.AddMethod(passPhrase);

            Stream encOut = encGen.Open(output, processedData.Length);

            encOut.Write(processedData, 0, processedData.Length);
            encOut.Close();

            if (armor)
                output.Close();

            return bOut.ToArray();
        }

        public byte[] Encrypt(byte[] inputData, byte[] publicKey)
        {
            Stream publicKeyStream = new MemoryStream(publicKey);

            PgpPublicKey encKey = ReadPublicKey(publicKeyStream);

            return Encrypt(inputData, encKey, true, true);
        }

        private static byte[] Compress(byte[] clearData, string fileName, CompressionAlgorithmTag algorithm)
        {
            MemoryStream bOut = new MemoryStream();

            PgpCompressedDataGenerator comData = new PgpCompressedDataGenerator(algorithm);
            Stream cos = comData.Open(bOut); // open it with the final destination
            PgpLiteralDataGenerator lData = new PgpLiteralDataGenerator();

            // we want to Generate compressed data. This might be a user option later,
            // in which case we would pass in bOut.
            Stream pOut = lData.Open(
            cos,                    // the compressed output stream
            PgpLiteralData.Binary,
            fileName,               // "filename" to store
            clearData.Length,       // length of clear data
            DateTime.UtcNow         // current time
            );

            pOut.Write(clearData, 0, clearData.Length);
            pOut.Close();

            comData.Close();

            return bOut.ToArray();
        }

        private const int BufferSize = 512;

        public static void PipeAll(Stream inStr, Stream outStr)
        {
            byte[] bs = new byte[BufferSize];
            int numRead;
            while ((numRead = inStr.Read(bs, 0, bs.Length)) > 0)
            {
                outStr.Write(bs, 0, numRead);
            }
        }

        

    }
```

And our unit test has to be success.
```c#
    [Fact]
    public void PgpEncryptDecryptTest()
    {
        var input = Encoding.ASCII.GetBytes("test 1");

        var publicKey = File.ReadAllBytes("Resources/pbk.txt");

        var pgp = new Pgp();

        var encrBytes = pgp.Encrypt(input , publicKey);

        var privateKey = File.OpenRead("Resources/privateKey.txt");

        var decrypted = Pgp.Decrypt(encrBytes, privateKey, "pass");

        Assert.Equal("test 1", Encoding.ASCII.GetString(decrypted));
    }
```