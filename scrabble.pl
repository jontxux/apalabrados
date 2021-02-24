#!/usr/bin/env perl -w

use strict;
use warnings;
use v5.32;
use utf8::all;
use Path::Tiny;

my $palabra_almacenada = Path::Tiny->tempfile;
my $run                = Path::Tiny->tempfile;
$run->spew(1);
my $nombre_fichero = "todas.txt";
generar_diccionario($nombre_fichero) unless path($nombre_fichero)->exists;
my $todas = path($nombre_fichero)->slurp;

my $pid = fork;
if ($pid) {
	my $vieja_palabra = "";
	my $palabra       = "";
	while ( $run->slurp ) {
		my $comando = << 'BASH';
import -window root -depth 8 -crop 650x100+1100+925 png:- | \
convert - -threshold 50% png:- | \
tesseract --dpi 300 stdin stdout 2> /dev/null
BASH
		$palabra = qx{$comando};
		$palabra =~ s/\t|\s|\n//g;
		$palabra = lc($palabra);

		if ( 1 < length $palabra < 10 && $vieja_palabra ne $palabra ) {
			$vieja_palabra = $palabra;
			buscar_palabras( $palabra, \$todas );
			$palabra_almacenada->spew($palabra);
		}
		sleep 1;
	}
}
else {
	while ( $run->slurp ) {
		if ( -e $palabra_almacenada ) {

			my $input = <STDIN>;
			chomp($input);
			$input = lc($input);

			if ( $input =~ /^exit$/ ) {

				# $run = 0;
				$run->spew(0);
				last;
			}
			elsif ( $input =~ /^\s/ ) {
				$input =~ s/\s+|\t+//g;
				buscar_palabras( $input, \$todas );
			}
			elsif (length($input) > 0){
				buscar_palabras( $palabra_almacenada->slurp . $input, \$todas );
			}
		}
		sleep 1;
	}
	exit;
}

sub buscar_palabras {
	my $palabra = shift;
	my $todas   = shift;

	# Quitar las letras que no estan en la palabra
	my $len = length $palabra;
	say $len;
	my $busqueda = eval { qr/[$palabra]{2,$len}/ };
	say $busqueda;

	my @extraidas = $todas->$* =~ m/\b$busqueda\b/g;

	my $letras_busqueda =
	  do { my %l; $l{$_}++ for @{ [ split //, $palabra ] }; \%l };

	my @definitivo = grep {
		my $ok = 1;
		my %l  = %$letras_busqueda;
		for my $letra ( split // ) {
			unless ( $l{$letra}-- ) {
				$ok = 0;
				last;
			}
		}
		$ok;
	} @extraidas;

	@definitivo = sort { length $a <=> length $b } @definitivo;
	say $_ . " " . length($_) for @definitivo;
}

sub generar_diccionario {

	my $nombre_fichero = shift;

	say "No tiene el diccionario creado";

	my $path        = Path::Tiny->new($nombre_fichero);
	my $diccionario = qx{aspell -d es dump master | aspell -l es expand};
	$diccionario =~ s/\s|\ŧ|\n/:/sg;
	$diccionario =~ tr/áéíóú/aeiou/s;
	my @diccionario_repetido = split /:/, $diccionario;
	my @unique     = keys { map { $_ => 1 } @diccionario_repetido }->%*;
	my @definitivo = map { "$_\n" } @unique;
	@definitivo = sort { $a cmp $b } @definitivo;
	$path->spew(@definitivo);

	say "Diccionario creado";
}

