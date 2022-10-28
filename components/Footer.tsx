import styles from './Footer.module.css';

export default function Footer() {
    return (
        <>
            <div className={styles.footer}>
                <p><a href='https://reddit.com/r/UlryApp'>r/UlryApp</a></p>
                <p><a href='https://github.com/mattrighetti/Ulry'>GitHub</a></p>
                <p><a href='https://testflight.apple.com/join/QJVKOkdK'>TestFlight</a></p>
                <p><a href='https://mattrighetti.com'>Developer Website</a></p>
            </div>
        </>
    )
}