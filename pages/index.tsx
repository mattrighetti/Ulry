import type { NextPage } from 'next';
import Feature from '../components/Feature';
import Footer from '../components/Footer';
import Hero from '../components/Hero';
import ButtonSection from '../components/ButtonSection';
import Head from 'next/head'

const Home: NextPage = () => {
    return (
        <>
            <Head>
                <title>Ulry</title>
                <meta name="theme-color" content="#333333" media="(prefers-color-scheme: light)" />
                <meta name="theme-color" content="#333333" media="(prefers-color-scheme: dark)" />
            </Head>
            <Hero />
            <ButtonSection />
            <Feature img="/images/home.png" title="Minimalistic UI" body="Ulry was designed with simplicity in mind, the user interface is crafted to show you what really matters." odd={true} />
            <Feature img="/images/link-list.png" title="All in a single place" body="Find all your favourite links in a single place. You can order them, you can star them and you can also check which you've read and which you haven't and much more..." odd={false} />
            <Feature img="/images/details-2.png" title="Need more details?" body="Ulry can show you more info about a particular link, you can even attach a note to it so that you won't forget what you wanted to do with it." odd={true} />
            <Feature img="/images/add-shortcut.png" title="Save from everywhere" body="Ulry comes with useful shortcuts that will let you save your favourite articles and websites directly from Safari and other apps on your phone." odd={false} />
            <Feature img="/images/add-group.png" title="Highly customisable" body="Everything that you see in Ulry is under your control, you can change group icons and colors, same goes for tags." odd={true} />
            <Feature img="/images/redirector.png" title="Redirections" body="Are you tired of paywalled articles or websites that require you to sign in? Ulry got you covered! With redirections you can tell Ulry which websites you would like to be redirected to for specific websites" odd={false} />
            <Footer />
        </>
    )
}

export default Home
