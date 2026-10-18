package config

import (
	"encoding/base64"
	"errors"
	"reflect"

	"github.com/rs/zerolog/log"
	"github.com/spf13/viper"
)

// Config is read from environment variables only.
type Config struct {
	DatabaseURL        string `mapstructure:"DATABASE_URL"`
	Port               int    `mapstructure:"PORT"`
	EncryptionKey      string `mapstructure:"ENCRYPTION_KEY"`
	VerifyDomainSecret string `mapstructure:"VERIFY_DOMAIN_SECRET"`
	Emailer            string `mapstructure:"EMAILER"`
	ResendAPIKey       string `mapstructure:"RESEND_API_KEY"`
	DashboardURL       string `mapstructure:"DASHBOARD_URL"`
	JWTPrivateKey      string `mapstructure:"JWT_PRIVATE_KEY"`
}

func LoadConfig() (*Config, error) {
	t := reflect.TypeOf(Config{})
	for i := 0; i < t.NumField(); i++ {
		if tag := t.Field(i).Tag.Get("mapstructure"); tag != "" {
			if err := viper.BindEnv(tag); err != nil {
				log.Warn().Err(err).Str("config_tag", tag).Msg("failed to bind env")
				continue
			}
		}
	}

	viper.AutomaticEnv()

	var cfg Config
	if err := viper.Unmarshal(&cfg); err != nil {
		return nil, err
	}

	if err := cfg.Validate(); err != nil {
		return nil, err
	}

	return &cfg, nil
}

func (c *Config) Validate() error {
	if c.DatabaseURL == "" {
		return errors.New("DATABASE_URL is required")
	}
	if c.DashboardURL == "" {
		return errors.New("DASHBOARD_URL is required")
	}
	if c.Port == 0 {
		return errors.New("PORT is required")
	}
	if c.EncryptionKey == "" {
		return errors.New("ENCRYPTION_KEY is required")
	}
	key, err := base64.StdEncoding.DecodeString(c.EncryptionKey)
	if err != nil {
		return errors.New("ENCRYPTION_KEY must be base64 encoded")
	}
	if len(key) != 32 {
		return errors.New("ENCRYPTION_KEY must be 32 bytes (256-bit)")
	}
	if c.VerifyDomainSecret == "" {
		return errors.New("VERIFY_DOMAIN_SECRET is required")
	}
	return nil
}

func (c *Config) GetEncryptionKey() ([]byte, error) {
	return base64.StdEncoding.DecodeString(c.EncryptionKey)
}
