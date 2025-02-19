# Sample docker-compose file for pulse mode

## Usage

Copy the provided `sample.env` to `.env`:

```text
cp sample.env .env
```

Edit with your favorite editor, the run with:

```text
docker-compose up -d
```

## Caveat

Music plays faster than it should with this configuration. Maybe because I did not setup anything that reads the fifo file. Maybe some knowledgeable users can help me with this!
